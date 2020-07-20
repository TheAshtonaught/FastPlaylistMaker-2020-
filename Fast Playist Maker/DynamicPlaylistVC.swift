//
//  DynamicPlaylistVC.swift
//  Fast Playist Maker
//
//

import UIKit
import Firebase
import MediaPlayer
import StoreKit
import AVKit

class DynamicPlaylistVC: UIViewController {
    
    @objc var playlistID: String?
    @objc var fetchLibraryView: LoadingLibraryUI!
    var songs = [Song]()
    @objc var ref: DatabaseReference!
    @objc var playlistTitle: String?
    let appleMusicClient = AppleMusicConvenience.sharedClient()
    let spotifyClient = SpotifyClient.sharedClient()
    @objc let controller = SKCloudServiceController()
    @objc let mpController = MPMusicPlayerController.systemMusicPlayer
    var hasAppleMusicAccess: Bool?
    @objc var storeIds = [String]()
    @objc var player = AVPlayer()
    @objc var queries = [String]()
    @objc var interstitial: GADInterstitial!
    
    @IBOutlet weak var playlistTableView: UITableView!
    @IBOutlet weak var PlaylistTitlelabel: UILabel!
    @IBOutlet weak var playButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        ref = Database.database().reference()

        configureUI()
        checkAppleMusicAccess()

        receiveSpotifyAuthNotifications()
        interstitial = createAndLoadInterstitial()
        interstitial.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //TODO: move to view did load
        if let id = playlistID {
            parsePlaylist(id: id)
        } else {
            showHomeTabBar(shouldAnimateToMusicPlayer: false)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func play(_ sender: Any) {
        //displayAD(interstitial: interstitial)
        
        let hasAppleMusicAccess = self.hasAppleMusicAccess ?? false
        if !hasAppleMusicAccess  {
            displaySpotifyAlert(songToPrepend: nil)
        } else {
            playlistPlayback(songToPrepend: nil)
        }

        
        
    }
    
    @IBAction func exit(_ sender: Any) {
        
        showHomeTabBar(shouldAnimateToMusicPlayer: false)
    }
    
    @objc func parsePlaylist(id: String) {
        if id.isEmpty {
        
            showHomeTabBar(shouldAnimateToMusicPlayer: false)
        }
        
        ref.child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let value = snapshot.value as? NSDictionary else {
                print("no value from playlist id")
                return
            }
            
            self.setPlaylistTitle(playlistDict: value)
            self.parsePlaylistSongs(playlistDict: value)
            
            self.setplayButton(isHidden: false)
        })
        
    }
    
    @objc func parsePlaylistSongs(playlistDict: NSDictionary) {
        guard let songDict = playlistDict["songs"] as? NSDictionary else {
            print("error getting playlist songs")
            DispatchQueue.main.async {
                self.showHomeTabBar(shouldAnimateToMusicPlayer: false)
            }
            return
        }
        
        for (_, value) in songDict {
            if let valueDict = value as? NSDictionary, let title = valueDict["title"] as? String, let artist = valueDict["albumArtist"] as? String {
                let searchString = "\(title) \(artist)"

                queries.append(searchString)
                
                if let playbackId = valueDict["playbackId"] as? String, playbackId != "0" {
                    
                    getSong(fromPlaybackID: playbackId)
                } else {
                    getSong(fromSearchTerm: searchString)
                }
                
            }
        }
        DispatchQueue.main.async {
           self.removeFetchLibView()
        }
        
    }
    
    @objc func getSong(fromPlaybackID playbackId: String) {
        appleMusicClient.addSong(fromTrackId: playbackId) { (song) in
            guard let song = song else {
                return
            }

            self.songs.append(song)
            
            DispatchQueue.main.async {
                self.playlistTableView.reloadData()
                self.showTableView()
            }
        }
    }
    
    @objc func getSong(fromSearchTerm searchTerm: String) {
        appleMusicClient.addSong(searchTerm: searchTerm, completion: { (song) in
            
            guard let song = song else {
                return
            }

            self.songs.append(song)
            DispatchQueue.main.async {
                self.playlistTableView.reloadData()
                self.showTableView()
            }
            
        })
    }
    
    @objc func setPlaylistTitle(playlistDict: NSDictionary) {
        guard let playlistTitle = playlistDict["PLAYLIST_TITLE"] as? String else {
            DispatchQueue.main.async {
                self.PlaylistTitlelabel.text = "Untitled"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.PlaylistTitlelabel.text = playlistTitle.uppercased()
        }
    }
    
    func playlistPlayback(songToPrepend: Song?) {
        mpController.stop()
        mpController.prepareToPlay()
        
        let hasAppleMusicAccess = self.hasAppleMusicAccess ?? false
        
        if hasAppleMusicAccess {
            
            mpController.setQueue(with: [""])
            for song in songs {
                guard let id = song.trackId?.description else{
                    return
                }
                
                storeIds.append(id)
            }
            
            if let selectedSong = songToPrepend, let selectedId = selectedSong.trackId?.description {

                storeIds.insert(selectedId, at: 0)
                
                mpController.shuffleMode = .off
            }
            //print(storeIds)
            
            mpController.setQueue(with: storeIds)
            
            mpController.play()
            showHomeTabBar(shouldAnimateToMusicPlayer: true)
            
        } else {
            
           displaySpotifyAlert(songToPrepend: songToPrepend)
        }
    }
    
    func playPreviewTracks(song: Song?) {
       
        var previewSong: Song?
        
        if let sng = song {
            previewSong = sng
        } else {
            previewSong = songs.first
        }
        
        guard let previewUrl = previewSong?.previewUrl else {
            return
        }
        
        guard let streamURL = URL(string: previewUrl) else {
            return
        }
        
        let playerItem:AVPlayerItem = AVPlayerItem(url: streamURL)
        player = AVPlayer(playerItem: playerItem)
        player.play()
        playButton.setTitle("PAUSE", for: .normal)

        displayPreviewMessage()
    }
    
    @objc func showHomeTabBar(shouldAnimateToMusicPlayer: Bool) {
        guard let initialTab = self.storyboard?.instantiateViewController(withIdentifier: "initialTabBar") as? UITabBarController else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        present(initialTab, animated: true, completion: {
            if shouldAnimateToMusicPlayer {
                initialTab.animateToTab(toIndex: 2)
            }
        })
    }
    
    @objc func showTableView() {
        if self.playlistTableView.isHidden {
            self.playlistTableView.isHidden = false
        }
    }
    
    @objc func displayPreviewMessage() {
        let alert = UIAlertController(title: "Playing Preview", message: "You are listening to a preview of this track you must have access to Apple Music or Spotify", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Got it", style: .cancel, handler: nil))
        
        alert.view.backgroundColor = .white
        alert.view.layer.cornerRadius = 15
        
        present(alert, animated: true, completion: nil)
    
    }
    
    func displaySpotifyAlert(songToPrepend: Song?) {
        let alert = UIAlertController(title: "Play On Spotify", message: "Would you like to listen to this playlist on Spotify?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { (_) in
            self.spotifyClient.loginToSpotify()
        }))
        
        alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: { (_) in
            
            if self.player.currentItem != nil {
                self.player = AVPlayer()
                self.playButton.setTitle("PLAY", for: .normal)
            } else {
                self.playPreviewTracks(song: songToPrepend)
            }
        }))
        
        
        alert.view.backgroundColor = .white
        alert.view.layer.cornerRadius = 15
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func configureUI() {
        setFetchLibView()
        configureTableViewStyle()
        configureButton()
        setplayButton(isHidden: true)
        playlistTableView.isHidden = true
    }
    
    @objc func configureTableViewStyle() {
        playlistTableView.layer.cornerRadius = 10
        playlistTableView.layer.masksToBounds = true
    }
    
    @objc func configureButton() {
        
    }

}

//MARK: TableViewDelegate

extension DynamicPlaylistVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DynamicSongTableCell") as? SongTableCell else {
            return UITableViewCell()
        }
        
        let song = songs[indexPath.row]
        
        cell.songTitleLbl.text = song.title
        cell.albumTitleLbl.text = song.artist
        
        DispatchQueue.main.async {
            cell.albumImageView.loadImageUsingUrlString(urlString: song.imageUrl)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let song = songs[indexPath.row]
        
        playlistPlayback(songToPrepend: song)
       // playPreviewTracks(song: song)
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
}

extension DynamicPlaylistVC {
    
    @objc func setFetchLibView() {
        let mainView = self.view!
        
        fetchLibraryView = Bundle.main.loadNibNamed("FetchLibrary", owner: self, options: nil)?.first as? LoadingLibraryUI
        
        fetchLibraryView.frame.size = CGSize(width: 350, height: 300)
        fetchLibraryView.center = mainView.center
        
        mainView.addSubview(fetchLibraryView)
        
        fetchLibraryView.cheetahAnimation(animate: true)
    }
    
    @objc func removeFetchLibView() {
        self.fetchLibraryView.cheetahAnimation(animate: false)
        self.fetchLibraryView.removeFromSuperview()
    }
    
    @objc func setplayButton(isHidden: Bool) {
        
        playButton.isHidden = isHidden
        playButton.isUserInteractionEnabled = !isHidden
    }
}

extension DynamicPlaylistVC {
    
    @objc func checkAppleMusicAccess() {
        SKCloudServiceController.requestAuthorization { (status) in
            if status == SKCloudServiceAuthorizationStatus.authorized {
                self.checkAppleMusicCapabilities()
            }
        }
        
        
    }
    
    @objc func checkAppleMusicCapabilities() {
        self.controller.requestCapabilities { (capabilities, error) in
            if error != nil {
                self.hasAppleMusicAccess = false
            } else {
                
                if capabilities.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                    self.hasAppleMusicAccess = true
                }
                
            }
            
        }
    }
    
}




//MARK: Spotify Auth
extension DynamicPlaylistVC {
    
    @objc func receiveSpotifyAuthNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.spotifyTokenRequest(_:)), name: NSNotification.Name(rawValue: "spotifyAuth"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.getSpotifySongs(_:)), name: NSNotification.Name(rawValue: "receivedSpotifyToken"), object: nil)
    }
    
    @objc func spotifyTokenRequest(_ notif: NSNotification) {
        
        guard let code = notif.userInfo?["code"] as? String else {
            return
        }
        
        spotifyClient.spotifyTokenRequest(code: code)
    }
    
    @objc func getSpotifySongs(_ notif: NSNotification) {
        let dispatchGroup = DispatchGroup()
        var spotifyTrackIds = [String]()
        
        guard let token = notif.userInfo?["token"] as? String else {
            return
        }
        
        for query in queries {
            dispatchGroup.enter()

            spotifyClient.getSpotifyTrackId(token: token, query: query, completionHandler: { (id) in
                if let id = id {
                    spotifyTrackIds.append(id)
                }
                dispatchGroup.leave()
            })
            
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main, execute: {
        
            self.spotifyClient.launchSpotifyPlaylist(token: token, spotifyTrakIds: spotifyTrackIds, name: self.PlaylistTitlelabel.text ?? "no title")
//            print(spotifyTrackIds)
        })
    }
    
    
}

//MARK: AdMob
extension DynamicPlaylistVC: GADInterstitialDelegate {
    
    
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {

        interstitial = createAndLoadInterstitial()
        playlistPlayback(songToPrepend: nil)

        
    }
    
    
}

extension UIViewController {
    
    @objc func createAndLoadInterstitial() -> GADInterstitial {
        let adUnitId = "ca-app-pub-3821799418903504/6627238679"
//        let testAd = "ca-app-pub-3940256099942544/4411468910"
        
        let interstitial = GADInterstitial(adUnitID: adUnitId)
        interstitial.load(GADRequest())
        return interstitial
    }
    
    @objc func displayAD(interstitial: GADInterstitial) {
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        }
    }
}












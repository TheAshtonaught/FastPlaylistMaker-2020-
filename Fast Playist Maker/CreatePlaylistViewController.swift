//
//  CreatePlaylistVC.swift
//  Fast Playist Maker
//
//

import UIKit
import Koloda
import MediaPlayer
import StoreKit
import CoreData
import Firebase

class CreatePlaylsitViewController: UIViewController {
    
    //MARK: Properties
    
    var addedSongs = [Song]()
    var similarSongsArray = [SimilarSong]()
    @objc var positionInSongArray = 0
    @objc var savedSongs = [SavedSong]()
    @objc let controller = SKCloudServiceController()
    @objc var showingSimilarSong = false
    var userLibrary: [Song]?
    @objc var playlistTitle: UITextField!
    @objc var appDel: AppDelegate!
    var global = Global.sharedClient()
    let appleMusicClient = AppleMusicConvenience.sharedClient()
    let lastFmClient = LastFmConvenience.sharedClient()
    var stack: CoreDataStack!
    @objc var fetchLibraryView: LoadingLibraryUI!
    @objc var interstitial: GADInterstitial!
    var songArray: [Song]? {
        didSet {
            DispatchQueue.main.async {
                self.kolodaView.reloadData()
                self.kolodaView.isHidden = false
                self.removeFetchLibView()
                self.checkIfFirstLaunch()
            }
        }
    }
    
    //MARK: Outlets
    
    @IBOutlet weak var kolodaView: KolodaView!
    @IBOutlet weak var createPlaylistBtn: BorderedButton!
    @IBOutlet weak var discoverSwitch: UISwitch!
    
    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setFetchLibView()
        
        kolodaView.dataSource = self
        kolodaView.delegate = self
        kolodaView.isHidden = true
        
        getLibrary()

        appDel = UIApplication.shared.delegate as? AppDelegate
        stack = appDel.stack
        interstitial = createAndLoadInterstitial()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        setNavBar(isHidden: true)
        
        loadPurgatorySongs()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        setNavBar(isHidden: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        lastFmClient.stopTask()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: Actions
    
    @IBAction func createPlaylist(_ sender: Any) {
        if let currentPlaylist = global.currentPlaylist {
            addSongsToCurrentPlaylist(playlist: currentPlaylist)
            global.currentPlaylist = nil
        } else {
            createPlaylistButtonPressed()
        }
        
    }
    
    @IBAction func discoverSwitchValueChanged(_ sender: Any) {
        
        similarSongsArray = [SimilarSong]()
        
        if discoverSwitch.isOn {
            if addedSongs.count > 0 {
                
                getSimilarSongs()
            } else {
                displayAlert("No songs added", errorMsg: "Discover suggest new songs based on songs you've added to your current playlist")
                discoverSwitch.isOn = false
            }
        } else if !discoverSwitch.isOn {
            kolodaView.resetCurrentCardIndex()
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        
        if addedSongs.count > 0 {
            cancelPlaylistWarning()
        }
    }
    
    @IBAction func search(_ sender: Any) {
        
        let searchVC = self.storyboard?.instantiateViewController(withIdentifier: "AMSearchVC") as! AMSearchVC
        searchVC.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    @IBAction func musicLibraryBtnPressed(_ sender: Any) {
        
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.delegate = self
        picker.allowsPickingMultipleItems = true
        
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func moreInfo(_ sender: Any) {
        
    }
    
    @objc func getLibrary() {
        
        MPMediaLibrary.requestAuthorization { (status) in
            if status == .authorized {
                
                if let songItems = MPMediaQuery.songs().items {
                    
                    self.songArray = Song.newSongFromMPItemArray(itemArr: songItems.shuffled())
                    
                    self.userLibrary = self.songArray
                    print(self.songArray?.count ?? 0)
                    
                } else {
                    
                    DispatchQueue.main.async {
                        self.removeFetchLibView()
                        
                        self.displayAlert("No songs to show", errorMsg: "Do you have songs in your music Library? If so, please make sure that Playlist Cheetah has access to your music library in your settings.")
                    }
                }
            } else {
                
                DispatchQueue.main.async {
                    self.removeFetchLibView()
                    
                    self.displayAlert("Can't Get Songs From Your Library", errorMsg: "Playlist Cheetah does not have access to your music library. Please check your settings and allow Playlist Cheetah to have access to your library if you want to use songs from your library to make playlist")
                }
            }
        }
    }
    
    func added(song: Song) {
        addedSongs.append(song)

        if addedSongs.count > 0 {
            createPlaylistBtn.alpha = 1
            createPlaylistBtn.isEnabled = true
            discoverSwitch.isEnabled = true
        }

    }
    
    @objc func resetLib() {
        songArray = userLibrary?.shuffled()
        addedSongs.removeAll(keepingCapacity: true)

        similarSongsArray = [SimilarSong]()
        createPlaylistBtn.alpha = 0.3
        
        kolodaView.resetCurrentCardIndex()
    }
    
    @objc func loadPurgatorySongs() {
        if let amsongs = global.appleMusicPicks {
            addedSongs.append(contentsOf: amsongs)
            if addedSongs.count > 0 {
                createPlaylistBtn.alpha = 1
                createPlaylistBtn.isEnabled = true
                discoverSwitch.isEnabled = true
            }
            global.appleMusicPicks = nil
        }
    }
    
    @objc func getSimilarSongs() {
        let myGroup = DispatchGroup()
        
        for song in addedSongs {
            myGroup.enter()
            lastFmClient.getSimilarSongs(song: song, completionHandler: { (song, error) in
                
                if let err = error {
                    print(err)
                }
                
                if let songArray = song {
                    self.similarSongsArray.append(contentsOf: songArray)
                    
                }
                myGroup.leave()
            })
        }
        
        myGroup.notify(queue: DispatchQueue.main, execute: {
            self.displaySimilarSongs()
        })

    }
    
    @objc func displaySimilarSongs() {
        print(similarSongsArray.count)
        similarSongsArray.sort(by: { $0.match > $1.match })
        positionInSongArray = self.kolodaView.currentCardIndex
        showingSimilarSong = true
        kolodaView.reloadData()
        kolodaView.resetCurrentCardIndex()
        songArray!.removeSubrange(0..<positionInSongArray)
    }

    func getAppleMusicVersionOfSimilarSong(song: Song, completion: @escaping (_ song: Song?) -> Void) {
        appleMusicClient.addSimilarSongToLibrary(similarSong: song, completion: completion)
        
    }
    
    func addSongToLibrary(song: Song, completion: @escaping (_ success: Bool?) -> Void) {
        getAppleMusicVersionOfSimilarSong(song: song, completion: { (sng) in
            
            if let song = sng {
                let pID = String(song.persitentID)
                
                self.controller.requestCapabilities(completionHandler: { (capability, error) in
                    if capability.contains(SKCloudServiceCapability.addToCloudMusicLibrary)  {
                        MPMediaLibrary.default().addItem(withProductID: pID, completionHandler: { (arr, err) in
                            
                            if err == nil {
                                completion(true)
                            }
                            
                        })
                    }
                })
                
            }
        })
    }
    
    @objc func addSongsToPlaylist() {
        
        let playlist = Playlist(title: playlistTitle.text ?? "Untitled", context: stack.mainContext)
        
        for song in addedSongs {
            if song.persitentID == AppleMusicConvenience.ids.similarSongId {
                addSimilarSongTolibrary(song: song, playlist: playlist)
                
            } else {
                let savedSong = SavedSong(song: song, context: stack.mainContext)
                
                savedSong.playlist = playlist
            }
            
        }
        stack.save()
        resetLib()
        DispatchQueue.main.async {
            self.presentSongTable(playlist: playlist)
        }
        
    }
    
    @objc func addSongsToCurrentPlaylist(playlist: Playlist) {
        
        for song in addedSongs {
            if song.persitentID == AppleMusicConvenience.ids.similarSongId {
                addSimilarSongTolibrary(song: song, playlist: playlist)
                
            } else {
                let savedSong = SavedSong(song: song, context: stack.mainContext)
                
                savedSong.playlist = playlist
            }
            
        }
        stack.save()
        resetLib()
        DispatchQueue.main.async {
            self.presentSongTable(playlist: playlist)
        }
        
    }
    
    func addSimilarSongTolibrary(song: Song, playlist: Playlist) {
        addSongToLibrary(song: song, completion: { (success) in
            if let success = success {
                if success {
                    let savedSong = SavedSong(song: song, context: self.stack.mainContext)
                    savedSong.playlist = playlist
                }
            }
        })
    }
    
    @objc func createPlaylistButtonPressed() {
        func configTextField(textField: UITextField) {
            textField.placeholder = "workout"
            playlistTitle = textField
        }
        
        func cancel(alertView: UIAlertAction!){
            
        }
        
        let alert = UIAlertController(title: nil, message: "You've just created something EPIC give it a Name", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: configTextField)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { (UIAlertAction) in
            if let text = self.playlistTitle.text, !text.isEmpty {
                self.addSongsToPlaylist()
            } else {
                self.displayAlert("No Title", errorMsg: "Pleast name your playlist")
            }
        }))
        
        if addedSongs.count > 0 {
            present(alert, animated: true, completion: nil)
        } else {
            displayAlert("NO SONGS ADDED", errorMsg: "Add songs to a playlist by swiping right on the song you want to add")
        }
    }
    
    @objc func presentSongTable(playlist: Playlist) {
        guard let songListTableVC = self.storyboard?.instantiateViewController(withIdentifier: "SongListTableVC") as? SongListTableVC else {
            return
        }
        songListTableVC.playlist = playlist
        songListTableVC.hidesBottomBarWhenPushed = true
        songListTableVC.shouldShowShareMessage = true

        self.navigationController?.pushViewController(songListTableVC, animated: true)
        //displayAD()
    }
    
    @objc func setFetchLibView() {
        let mainView = self.view!
        
        fetchLibraryView = Bundle.main.loadNibNamed("FetchLibrary", owner: self, options: nil)?.first as? LoadingLibraryUI
        
        fetchLibraryView.frame.size = CGSize(width: 250, height: 250)
        fetchLibraryView.center = mainView.center
        
        mainView.addSubview(fetchLibraryView)
        
        fetchLibraryView.cheetahAnimation(animate: true)
    }
    
    @objc func removeFetchLibView() {
        self.fetchLibraryView.cheetahAnimation(animate: false)
        self.fetchLibraryView.removeFromSuperview()
    }
    
    
    
    @objc func setNavBar(isHidden: Bool) {
        navigationController?.setNavigationBarHidden(isHidden, animated: !isHidden)
    }
    
}

// MARK: KolodaViewDelegate

extension CreatePlaylsitViewController: KolodaViewDelegate {
    
    @objc func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        
        if discoverSwitch.isOn {
            discoverSwitch.isOn = false
        }
        kolodaView.resetCurrentCardIndex()
    }
    
    @objc func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        
    }
    
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {
        
        if direction == .right {
            
            if discoverSwitch.isOn && similarSongsArray.count > 0 {
                
                let songToAdd = Song(similarSong: similarSongsArray[index], albumImage: similarSongsArray[index].loadImageUsingUrlString())
                added(song: songToAdd)
            } else if songArray != nil {
                //TODO: error handling
                let songToAdd = songArray![index]
                added(song: songToAdd)
            }
        }
        
    }

}

// MARK: KolodaViewDataSource

extension CreatePlaylsitViewController: KolodaViewDataSource {
    func kolodaSpeedThatCardShouldDrag(_ koloda: KolodaView) -> DragSpeed {
        return .default
    }

    
    @objc func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
        
        
        if similarSongsArray.count > 0 {
            return similarSongsArray.count
        } else if songArray != nil {
            return songArray!.count
        } else {
            return 0
        }

    }
    
    @objc func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        
        let cardContainer = Bundle.main.loadNibNamed("CardContainer", owner: self, options: nil)?.first as! CardContainer
        
        
        if discoverSwitch.isOn && similarSongsArray.count > 0 {
            if index < similarSongsArray.count {
                
                DispatchQueue.main.async {
                    cardContainer.setWithSong(similarSong: self.similarSongsArray[index])
                }
                
                return cardContainer
            }
            
        } else if songArray != nil {
            let song = songArray![index]
            
            DispatchQueue.main.async {
                cardContainer.setWithSong(song: song)
            }
            return cardContainer
        }
        
        return UIView()
    }
    
    @objc func koloda(_ koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
        return Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)?.first as? OverlayView
    }
 
}

extension CreatePlaylsitViewController {

    @objc func errorReturn(code: Int, description: String, domain: String)-> NSError {
        let userInfo = [NSLocalizedDescriptionKey: description]
        return NSError(domain: domain, code: code, userInfo: userInfo)
    }
    
    @objc func displayAlert(_ errorTitle: String, errorMsg: String) {
        let alert = UIAlertController(title: errorTitle, message: errorMsg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        
    }
    
    @objc func cancelPlaylistWarning() {
        let alert = UIAlertController(title: "Cancel Playlist", message: "Are you sure you want to cancel making playlist?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "I'M SURE", style: .default, handler: { (UIAlertAction) in
            self.resetLib()
        }))
        
        alert.view.backgroundColor = .white
        alert.view.layer.cornerRadius = 15
        
        present(alert, animated: true, completion: nil)
    }
}

extension CreatePlaylsitViewController: MPMediaPickerControllerDelegate {
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        let items = mediaItemCollection.items
        
        for item in items {
            let newSong = Song(songItem: item)
            added(song: newSong)
        }
        
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        dismiss(animated: true) {
            
        }
    }
    
}

extension CreatePlaylsitViewController {
    //MARK: Explainers
    
    @objc func checkIfFirstLaunch() {
        if let firstLaunch = UserDefaults.standard.value(forKey: "FirstLaunch") {
            if firstLaunch as! Bool {}
        } else {
            showExplainerThenDismiss()
            UserDefaults.standard.set(false, forKey: "FirstLaunch")
        }
        
    }
    
    @objc func showExplainerThenDismiss() {
        let swipeImg = UIImage(named: "swipeExplainer.png")
        let swipeImgView = UIImageView(frame: kolodaView.frame)
        swipeImgView.image = swipeImg
        swipeImgView.backgroundColor = UIColor.lightGray
        swipeImgView.alpha = 0.7
        var delayInNanoSeconds = UInt64(1.5) * NSEC_PER_SEC
        var time = DispatchTime.now() + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: time) {
            
            self.view.addSubview(swipeImgView)
        }
        
        delayInNanoSeconds = UInt64(4.5) * NSEC_PER_SEC
        time = DispatchTime.now() + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: time) {
            
            swipeImgView.removeFromSuperview()
        }
    }
    
}

//MARK: AdMob
extension CreatePlaylsitViewController: GADInterstitialDelegate {
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        
        interstitial = createAndLoadInterstitial()
        
    }
    
    
}
















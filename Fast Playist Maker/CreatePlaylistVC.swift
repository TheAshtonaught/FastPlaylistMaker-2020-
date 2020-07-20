//
//  CreatePlaylistVC.swift
//  Fast Playist Maker
//
//  **********************************************
//  Deprecated Not used anymore
//  **********************************************

import UIKit
import MediaPlayer
import StoreKit
import CoreData

class CreatePlaylistVC: UIViewController {
    
    
// MARK: Properties
    var songsArr = [Song]()
    var userLibrary = [Song]()
    @objc var savedSongs = [SavedSong]()
    var stack: CoreDataStack!
    var addedSongs = [Song]()
    var similarSongsArray = [SimilarSong]()
    @objc var currentIndex = 0
    @objc var playlistTitle: UITextField!
    @objc var appDel: AppDelegate!
    var global = Global.sharedClient()
    let appleMusicClient = AppleMusicConvenience.sharedClient()
    let lastFmClient = LastFmConvenience.sharedClient()
    @objc var showingSimilarSong = false
    @objc let controller = SKCloudServiceController()
    

// MARK: Outlets
    @IBOutlet weak var AlbumImgView: DraggableImage!
    @IBOutlet weak var songTitleLbl: UILabel!
    @IBOutlet weak var albumTitleLbl: UILabel!
    @IBOutlet weak var CreatePlaylistBtn: UIButton!
    @IBOutlet weak var addedLbl: UILabel!
    @IBOutlet weak var addPlaylistBtn: UIBarButtonItem!
    @IBOutlet weak var fetchLibBtn: UILabel!
    @IBOutlet weak var cheetah: UIImageView!
    @IBOutlet weak var suggestionsSwitch: UISwitch!
    @IBOutlet weak var songSuggestionLabel: UILabel!
    @IBOutlet weak var activityIndicatorOfSimilarSongs: UIActivityIndicatorView!
    @IBOutlet weak var info: UIBarButtonItem!

//MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDel = UIApplication.shared.delegate as? AppDelegate
        stack = appDel.stack
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector( self.drag(gesture:)))
        AlbumImgView.addGestureRecognizer(gesture)
    
        configUI(createMode: false)
        initializeLibrary()
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        lastFmClient.stopTask()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let amsongs = global.appleMusicPicks {
            addedSongs.append(contentsOf: amsongs)
            if addedSongs.count > 0 {
                CreatePlaylistBtn.alpha = 1
                CreatePlaylistBtn.isEnabled = true
                suggestionsSwitch.isEnabled = true
            }
            global.appleMusicPicks = nil
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        shouldShowExplainer()
    }

    @objc func initializeLibrary() {
        getLibrary { (songArray, error) in
            guard error == nil else {
                self.displayAlert("No songs to show", errorMsg: "Do you have songs in your music Library? If so, please make sure that Playlist Cheetah has access to your music library in your settings.")
                self.configUI(createMode: true)
                self.AlbumImgView.isUserInteractionEnabled = false
                
                return
            }
            if let Arr = songArray {
                self.songsArr = Arr
                self.userLibrary = Arr
                print(self.songsArr.count)
                DispatchQueue.main.async {
                    self.configUI(createMode: true)
                    self.updateSong()
                    self.checkIfFirstLaunch()
                }
            }
        }
    }

    func getLibrary(completion:@escaping(_ librarySongs: [Song]?, _ error: NSError?) -> Void) {
        MPMediaLibrary.requestAuthorization { (status) in
            if status == .authorized {
                let songs = MPMediaQuery.songs().items! as [MPMediaItem]
                
                if songs.count < 1 {
                    completion(nil, self.errorReturn(code: 0, description: "Could not get user library", domain: "MPlibrary"))
                } else {
                    completion(Song.newSongFromMPItemArray(itemArr: songs), nil)
                }
            } else {
                
                self.configUI(createMode: true)
                self.AlbumImgView.isUserInteractionEnabled = false
                completion(nil, self.errorReturn(code: 0, description: "Could not get user library", domain: "MPlibrary"))
            }
        }
    }
    
    // appends the songs the user has picked to add to an array
    @objc func added() {
        
        if showingSimilarSong {
            let simSong = similarSongsArray[currentIndex]
            let song = Song(artwork: #imageLiteral(resourceName: "noAlbumArt"), title: simSong.title, album: simSong.artist, id: AppleMusicConvenience.ids.similarSongId, artist: simSong.artist)
            addedSongs.append(song)
            
            similarSongsArray.remove(at: currentIndex)
        } else {
            addedSongs.append(songsArr[currentIndex])
            
            if addedSongs.count > 0 {
                CreatePlaylistBtn.alpha = 1
                CreatePlaylistBtn.isEnabled = true
                suggestionsSwitch.isEnabled = true
            }
            songsArr.remove(at: currentIndex)
        }
        
    }
    
    
    func addSimilarSongs(song: Song, completion: @escaping (_ song: Song?) -> Void) {
        appleMusicClient.addSimilarSongToLibrary(similarSong: song, completion: completion)
        
    }
    
    func addSongToLibrary(song: Song, completion: @escaping (_ success: Bool?) -> Void) {
        addSimilarSongs(song: song, completion: { (sng) in
            
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
    
    @objc func resetLib() {
        songsArr = userLibrary
        addedSongs.removeAll(keepingCapacity: true)
        updateSong()
        similarSongsArray = [SimilarSong]()
        CreatePlaylistBtn.alpha = 0.3
        //CreatePlaylistBtn.isEnabled = false
    }
    
    @objc func getSimilarSongs() {
        var simArray = [SimilarSong]()
        
        if addedSongs.count > 0 {
            for song in addedSongs {
                lastFmClient.getSimilarSongs(song: song, completionHandler: { (song, error) in
                    
                    if let songArray = song {
                        for similar in songArray {
                            
                            simArray.append(similar)
                        }
                    }
                    self.similarSongsArray = simArray
                })
            }
            
        }
    }
    
//MARK: Navigation
    // after playlist is created show table with list of songs
    @objc func presentSongTable() {
        //TODO: Refractor add to playlist
        
        let playlist = Playlist(title: playlistTitle.text!, context: stack.mainContext)
        
        for song in addedSongs {
            if song.persitentID == AppleMusicConvenience.ids.similarSongId {
                
                addSongToLibrary(song: song, completion: { (success) in
                    if let success = success {
                        if success {
                            let savedSong = SavedSong(song: song, context: self.stack.mainContext)
                            savedSong.playlist = playlist
                        }
                    }
                })
                
            } else {
                let savedSong = SavedSong(song: song, context: stack.mainContext)
                savedSong.playlist = playlist
            }
            
        }
        stack.save()
        resetLib()
        DispatchQueue.main.async {
            
            let songListTableVC = self.storyboard!.instantiateViewController(withIdentifier: "SongListTableVC") as! SongListTableVC
            songListTableVC.playlist = playlist
            songListTableVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(songListTableVC, animated: true)
        }
    }
    
//MARK: UI
    // allows song to be dragged left to add right to skip
    @objc func drag(gesture: UIPanGestureRecognizer) {
        
        let translation = gesture.translation(in: self.view)
        let imgView = gesture.view!
        
        imgView.center = CGPoint(x: imgView.bounds.width + translation.x, y: imgView.bounds.height + translation.y)
        
        let xFromCenter = imgView.center.x - self.view.bounds.width / 2
        let scale = min(100 / abs(xFromCenter), 1)
        var rotation = CGAffineTransform(rotationAngle: xFromCenter / 200)
        var stretch = rotation.scaledBy(x: scale, y: scale)
        
        imgView.transform = stretch
        if gesture.state == UIGestureRecognizer.State.ended {
            
            if imgView.center.x < 100 {
                //songsArr.remove(at: currentIndex)
                updateSong()
                setAddedLbl(added: false)
            } else if imgView.center.x > self.view.bounds.width - 100 {
                added()
                updateSong()
                setAddedLbl(added: true)
            }
            
            rotation = CGAffineTransform(rotationAngle: 0)
            stretch = rotation.scaledBy(x: 1, y: 1)
            imgView.transform = stretch
            
            imgView.center = CGPoint(x: self.view.bounds.width / 2, y: (UIApplication.shared.statusBarFrame.height + 44 + (imgView.frame.height / 2)))
        }
    }
    
    func loadSimilarSong(similarSong: SimilarSong, completion: (_ song: Song?) -> Void) {
        var newSong: Song
        
        newSong = Song(artwork: #imageLiteral(resourceName: "noAlbumArt"), title: similarSong.title, album: similarSong.artist, id: AppleMusicConvenience.ids.similarSongId, artist: similarSong.artist)
        
        completion(newSong)
        
    }
    
    // grabs random song an updates UI accordingly
    @objc func updateSong() {
        if suggestionsSwitch.isOn && similarSongsArray.count > 0 {
            
            let randIndex = Int(arc4random_uniform(UInt32((similarSongsArray.count))))
            currentIndex = randIndex
            
            let song = similarSongsArray[currentIndex]
            
            showingSimilarSong = true
            DispatchQueue.main.async {
                self.AlbumImgView.image = #imageLiteral(resourceName: "noAlbumArt")
                self.songTitleLbl.text = song.title
                self.albumTitleLbl.text = song.artist
            }
            
        } else if songsArr.count > 0 {
        let randIndex = Int(arc4random_uniform(UInt32((songsArr.count))))
            
        currentIndex = randIndex
        showingSimilarSong = false
            
            DispatchQueue.main.async {
                self.AlbumImgView.image = self.songsArr[self.currentIndex].artwork
                self.songTitleLbl.text = self.songsArr[self.currentIndex].title
                self.albumTitleLbl.text = self.songsArr[self.currentIndex].album
            }
        
            
        } else {
            displayAlert("error", errorMsg: "there was an error getting the next song")
        }
    }
    
    @objc func configUI(createMode: Bool) {
        activityIndicatorOfSimilarSongs.isHidden = true
        fetchLibBtn.isHidden = createMode
        cheetahAnimation(animate: !createMode)
        cheetah.isHidden = createMode
        
        AlbumImgView.isHidden = !createMode
        songTitleLbl.isHidden = !createMode
        albumTitleLbl.isHidden = !createMode
        CreatePlaylistBtn.isHidden = !createMode
        //CreatePlaylistBtn.isEnabled = false
        suggestionsSwitch.isHidden = !createMode
        //suggestionsSwitch.isEnabled = false
        songSuggestionLabel.isHidden = !createMode
        
        info.tintColor = .black
    }
    
    @objc func cheetahAnimation(animate: Bool) {
        var imgArray = [UIImage]()
        for i in 0...7 {
            imgArray.append(UIImage(named: "cheetah\(i)")!)
        }
        if animate {
            cheetah.animationImages = imgArray
            cheetah.animationDuration = 0.4
            cheetah.startAnimating()
        } else {
            cheetah.stopAnimating()
        }
    }
    // Temporarily presents a label when a song is added or skiped
    @objc func setAddedLbl(added: Bool) {
        if added {
            addedLbl.text = "Added"
            addedLbl.backgroundColor = UIColor.green
            addedLbl.isHidden = false
            Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.dismissAdded), userInfo: nil, repeats: false)
        } else {
            addedLbl.text = "Skip"
            addedLbl.backgroundColor = UIColor.red
            addedLbl.isHidden = false
            
            Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.dismissAdded), userInfo: nil, repeats: false)
        }
        
    }
    
    @objc func dismissAdded() {
        addedLbl.isHidden = true
    }
    
// MARK: Actions
    
    @IBAction func ceatePlaylist(_ sender: Any) {
        
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
            self.presentSongTable()
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
    
    
    
    @IBAction func songSuggestionSwitch(_ sender: Any) {
        
        if suggestionsSwitch.isOn {
            if addedSongs.count > 0 {
                getSimilarSongs()
            } else {
                displayAlert("No songs added", errorMsg: "Discover suggest new songs based on songs you've added to your current playlist")
                suggestionsSwitch.isOn = false
            }
        }
        
    }
    
    @IBAction func cancelPlaylist(_ sender: Any) {
        if addedSongs.count > 0 {
            cancelPlaylistWarning()
        }
    }
    
    @IBAction func infoButton(_ sender: Any) {
        
    }
    
    @IBAction func searchAppleMusicButtonPressed(_ sender: Any) {
        
        
        let searchVC = self.storyboard?.instantiateViewController(withIdentifier: "AMSearchVC") as! AMSearchVC
        searchVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(searchVC, animated: true)
    }
    

}

extension CreatePlaylistVC {
//MARK: Explainers
    
    @objc func checkIfFirstLaunch() {
        if let firstLaunch = UserDefaults.standard.value(forKey: "FirstLaunch") {
            if firstLaunch as! Bool {}
        } else {
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoginToAppleMusicVC") {
            present(vc, animated: true, completion: nil)
            }
        }
        
    }
    
    @objc func shouldShowExplainer() {
        if global.showExplainer != nil {
            showExplainerThenDismiss()
            UserDefaults.standard.set(false, forKey: "FirstLaunch")
        }
    }
    
    @objc func showExplainerThenDismiss() {
        let swipeImg = UIImage(named: "swipeExplainer.png")
        let swipeImgView = UIImageView(frame: AlbumImgView.frame)
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


extension CreatePlaylistVC {

//MARK: Errors & Alerts
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
        
        present(alert, animated: true, completion: nil)
    }
}



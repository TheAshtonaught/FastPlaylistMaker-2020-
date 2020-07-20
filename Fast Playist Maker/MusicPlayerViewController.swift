//
//  MusicPlayerViewController.swift
//  Fast Playist Maker
//
//
//  ********************************************
//  DEPRECATED
//  ********************************************



import UIKit
import MediaPlayer

class MusicPlayerViewController: UIViewController {

    @objc let controller = MPMusicPlayerController.systemMusicPlayer
    
    @IBOutlet weak var albumImage: UIImageView!
    @IBOutlet weak var songLable: UILabel!
    @IBOutlet weak var playPauseBtn: UIButton!
    @IBOutlet weak var artistLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        controller.beginGeneratingPlaybackNotifications()

        NotificationCenter.default.addObserver(self,selector:#selector(self.setPlaybackUI), name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: controller)

        setSongInfo()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setSongInfo()
    }
    
    deinit {
        controller.endGeneratingPlaybackNotifications()
    }
    
    @objc func setPlaybackUI() {
        if controller.playbackState == .playing {
            playPauseBtn.setImage(#imageLiteral(resourceName: "pauseTrack"), for: .normal)
        } else {
            playPauseBtn.setImage(#imageLiteral(resourceName: "playTrack"), for: .normal)
        }
        
        
    }
    
    @IBAction func playPauseBtn(_ sender: Any) {
        if controller.playbackState == .playing {
            controller.pause()
        } else { controller.play() }
        
        
    }
    
    @IBAction func previous(_ sender: Any) {
        controller.skipToPreviousItem()
        setSongInfo()
    }
    
    @IBAction func next(_ sender: Any) {
        controller.skipToNextItem()
        setSongInfo()
    }
    
    @IBAction func dismiss(_ sender: Any) {
        
        let initial = self.storyboard?.instantiateViewController(withIdentifier: "initialTabBar") as! UITabBarController
        
        navigationController?.pushViewController(initial, animated: true)
    }
    
    @IBAction func launchMusic(_ sender: Any) {
        let url = URL(string: "music://")!
        UIApplication.shared.open(url)
    }

    @objc func setSongInfo() {
        
        if let image = controller.nowPlayingItem?.artwork?.image(at: albumImage.frame.size) {
            albumImage.image = image
        } else {
            albumImage.image = #imageLiteral(resourceName: "noAlbumArt")
        }
        
        songLable.text = controller.nowPlayingItem?.title ?? ""
        artistLabel.text = controller.nowPlayingItem?.albumArtist ?? ""
        
    }
    
}

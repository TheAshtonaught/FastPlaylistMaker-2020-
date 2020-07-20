//
//  SongTableVC.swift
//  Fast Playist Maker
//
//

import UIKit
import CoreData
import MediaPlayer
import Firebase

class SongListTableVC: CoreDataTableVC {
// MARK: Properties
    @objc var playlist: Playlist!
    @objc var playlistTitle: String!
    var appleMusicClient = AppleMusicConvenience.sharedClient()
    let controller = MPMusicPlayerController.systemMusicPlayer
    var stack: CoreDataStack!
    @objc let activityIndicator = UIActivityIndicatorView(style: .gray)
    @objc var arr = [MPMediaItem]()
    var songsToAppend = [Song]()
    let global = Global.sharedClient()
    @objc var DBReference: DatabaseReference!
    @objc static let DYNAMIC_LINK_DOMAIN = "https://playlistcheetah.page.link"
    @objc var longLink: URL?
    @objc var shortLink: URL?
    @objc let bid: String? = "com.algebet.playlistcheetah1Xz"
    @objc let appStoreID = "1227601453"
    var shouldShowShareMessage: Bool?
    @objc var interstitial: GADInterstitial!
    
// MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = playlistTitle
        
        DBReference = Database.database().reference()
        
        let appDel = UIApplication.shared.delegate as! AppDelegate
        stack = appDel.stack

//        interstitial = createAndLoadInterstitial()
//        interstitial.delegate = self
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedSong")
        let pred = NSPredicate(format: "playlist = %@", playlist)
        fr.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fr.predicate = pred
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.mainContext, sectionNameKeyPath: nil, cacheName: nil)
        
        querysongs()
        
        let showShareMessage = shouldShowShareMessage ?? false
        
        if showShareMessage {
            shareplaylist()
            shouldShowShareMessage = nil
        }
    }
    
    @objc func querysongs() {
        
        guard let songs = fetchedResultsController?.fetchedObjects as? [SavedSong] else {
            return
        }
        
        
        for song in songs {
            let query = MPMediaQuery.songs()
            let songPredicate = MPMediaPropertyPredicate(value: song.title, forProperty: MPMediaItemPropertyTitle)
            query.addFilterPredicate(songPredicate)
            
            if let result = query.items?.first {
                arr.append(result)
            }
            
        }
    }
    
    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "AddSongsToPlaylistVC" {
            let vc = segue.destination as! AddSongsToPlaylistVC
            vc.playlist = self.playlist
        }
    }
    
    @objc func presentMusicPlayer() {

        tabBarController?.animateToTab(toIndex: 2)
    }

    @IBAction func play(_ sender: Any) {
        //displayAD(interstitial: interstitial)
        
        playlist.playSongsFromPlaylist(controller: controller)
        
        presentMusicPlayer()

    }
    
    @IBAction func addSongsBtnPressed(_ sender: Any) {
        
        global.currentPlaylist = playlist
        
        tabBarController?.animateToTab(toIndex: 0)
    }
    
    @IBAction func share(_ sender: Any) {
        
        shareplaylist()
    }
    
    
    func shareplaylist() {
        
        Auth.auth().signInAnonymously { (user, error) in
            if user != nil {
                
                self.buildFDLLink { (dynamicLink) in
                    if let link = dynamicLink {
                        self.showShareAlert(link: link)
                    }
                }
            }
        }
        
    }
    
    
    @objc func showShareAlert(link: URL) {
        
        DispatchQueue.main.async {
            func cancel(alertView: UIAlertAction!){
                
            }
            
            let alert = UIAlertController(title: nil, message: "Would you like to share this playlist?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: cancel))
            alert.addAction(UIAlertAction(title: "Share", style: .default, handler: { (UIAlertAction) in
                
                self.shareLink(link: link)
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        
        
        
    }
    
    @objc func shareLink(link: URL) {
        
        let message = "Hey, listen to the playlist I made " + link.absoluteString
        let shareSheet = UIActivityViewController(activityItems: [ message ], applicationActivities: nil)
        shareSheet.popoverPresentationController?.sourceView = self.view
        self.present(shareSheet, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let song = fetchedResultsController?.object(at: indexPath) as? SavedSong else {
            return UITableViewCell()
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SongTableCell", for: indexPath) as? SongTableCell else {
            return UITableViewCell()
        }

        cell.songTitleLbl.text = song.title
        cell.albumTitleLbl.text = song.albumTitle
        
        let uniqueString = "\(String(describing: song.title))\(String(describing: song.albumTitle))"
        DispatchQueue.main.async {
           cell.albumImageView.loadImageUsingCacheWithUniqueString(uniqueString, imageData: song.albumImg!) 
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedSong = fetchedResultsController?.object(at: indexPath) as? SavedSong else {
            return
        }
        var picked: MPMediaItem?
        
        for song in arr {
            if song.title == selectedSong.title {
                picked = song
            }
        }
        
        controller.stop()
        controller.prepareToPlay()
        let collection = MPMediaItemCollection(items: arr)
        controller.setQueue(with: collection)
        if let pick = picked {
            controller.nowPlayingItem = pick
        }
        controller.repeatMode = .all
        controller.play()
        presentMusicPlayer()        
    }
 
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            tableView.beginUpdates()
            
            if (fetchedResultsController?.fetchedObjects?.count)! > 1 {
                let song = fetchedResultsController?.object(at: indexPath) as! SavedSong
                stack.mainContext.delete(song)
                stack.save()
                
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
            tableView.endUpdates()
        }
    }
    

}

extension SongListTableVC {
    
    func buildFDLLink(completion: @escaping (_ link: URL?) -> Void) {
        
        guard let playlistID = uploadPlaylistToFirebase() else {
            //TODO: handle upload to firebase error
            return
        }
        
        let linkString = "https://www.playlistcheetah.com/\(playlistID)"
        
        guard let link = URL(string: linkString) else {
            print("ERROR CREATING URL FROM LINKSTRING")
            return
        }
        
        let components = DynamicLinkComponents(link: link, domainURIPrefix: SongListTableVC.DYNAMIC_LINK_DOMAIN)
        
        if let bundleID = bid {
            let iOSParams = DynamicLinkIOSParameters(bundleID: bundleID)
            
            iOSParams.appStoreID = appStoreID
            components?.iOSParameters = iOSParams
            
            longLink = components?.url
            
            //print(longLink?.absoluteString ?? "no long link")
            
            let options = DynamicLinkComponentsOptions()
            options.pathLength = .short
            components?.options = options
            
            components?.shorten { (shortURL, warnings, error) in
                // Handle shortURL.
                if let error = error {
                    print(error.localizedDescription + "no long link")
                    return
                }
                
                self.shortLink = shortURL
                print(self.shortLink?.absoluteString ?? "")
                completion(self.shortLink)
                
            }

        }
        
    }
    
    
    func uploadPlaylistToFirebase() -> String? {
        
        let playlistID = DBReference.childByAutoId().key
        
        let playlistTitle = self.playlist.name ?? "Not availaible"
        
        DBReference.child("\(playlistID!)").child("PLAYLIST_TITLE").setValue(playlistTitle)
        
        for i in 0..<arr.count {
            let song = arr[i]
            let songTitle = song.title ?? "No Title"
            let albumArtistString = song.artist ?? "No Title"
            let playbackId: String?
            if #available(iOS 10.3, *) {
                playbackId = song.playbackStoreID
            }else {
                playbackId = ""
            }
            
            let songDict = ["title": "\(songTitle)",
                "albumArtist": "\(albumArtistString)",
                "playbackId": "\(playbackId ?? "")"
            ]
            
            let songKeyString = "song " + String(format:  "%02d", i)
            
            DBReference.child("\(playlistID!)").child("songs").child(songKeyString).setValue(songDict)
            
        }
        
        return playlistID
    }
    
    
    @objc func tempFunc(playlistID: String) {
        
        guard let songs = fetchedResultsController?.fetchedObjects as? [SavedSong] else {
            return
        }
        
        for i in 0..<songs.count {
            let song = songs[i]
            let songTitle = song.title ?? "No Title"
            let albumArtistString = song.albumTitle ?? "No Title"
            
            let songDict = ["title": "\(songTitle)",
                "albumArtist": "\(albumArtistString)",
                "playbackId": "\("0")"
            ]
            
            let songKeyString = "song " + String(format:  "%02d", i)
            
            DBReference.child("\(playlistID)").child("songs").child(songKeyString).setValue(songDict)
            
        }
    }
    
    
}

extension SongListTableVC: GADInterstitialDelegate {
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        
        playlist.playSongsFromPlaylist(controller: controller)
        
        presentMusicPlayer()
    }
}














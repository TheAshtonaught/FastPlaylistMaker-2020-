//
//  Song.swift
//  Fast Playist Maker
//

//

import Foundation
import UIKit
import MediaPlayer

struct Song {
    
    var artwork: UIImage
    var title: String
    var album: String
    var persitentID: UInt64
    var artist: String
    var imageUrl: String
    var previewUrl: String?
    var trackId: Int?
    var playbackStoreId: String?
    
    init(artwork: UIImage, title: String, album: String, id: UInt64, artist: String) {
        self.artwork = artwork
        self.title = title
        self.album = album
        self.persitentID = id
        self.artist = artist
        self.imageUrl = ""
    }
    
    init(imageUrl: String, trackId: Int, previewUrl: String, artwork: UIImage, title: String, album: String, id: UInt64, artist: String) {
        self.artwork = artwork
        self.title = title
        self.album = album
        self.persitentID = id
        self.artist = artist
        self.imageUrl = imageUrl
        self.trackId = trackId
        self.previewUrl = previewUrl
        
        
    }
    
    init(similarSong: SimilarSong) {
        self.artist = similarSong.artist
        self.title = similarSong.title
        self.persitentID = similarSong.persitentID
        self.album = ""
        self.imageUrl = ""
        
        if let imageData = NSData(contentsOf: similarSong.imageUrl) as Data? {
            
            self.artwork = UIImage(data: imageData) ?? UIImage(named: "noAlbumArt.png")!
        } else {
            self.artwork = UIImage(named: "noAlbumArt.png")!
        }
    }
    
    init(savedSong: SavedSong) {
        self.artist = savedSong.albumTitle ?? ""
        self.title = savedSong.title ?? "NO TITLE"
        self.persitentID = UInt64(savedSong.id)
        self.album = savedSong.albumTitle ?? ""
        self.imageUrl = ""

        if let data = savedSong.albumImg as Data?, let albumimage = UIImage(data: data) {
            self.artwork = albumimage
        } else {
            self.artwork = #imageLiteral(resourceName: "noAlbumArt")
        }
    }
    
    static func songArray(fromSavedSongArray savedSongs: [SavedSong]) -> [Song] {
        var songArray = [Song]()
        for song in savedSongs {
            let item = Song(savedSong: song)
            songArray.append(item)
        }
        return songArray
    }
    
    init(similarSong: SimilarSong, albumImage: UIImage) {
        self.artist = similarSong.artist
        self.title = similarSong.title
        self.persitentID = similarSong.persitentID
        self.album = similarSong.artist
        self.artwork = albumImage
        self.imageUrl = ""
    }
    
    
    init(songItem: MPMediaItem) {
        
        if #available(iOS 10.3, *) {
            playbackStoreId = songItem.playbackStoreID
        }
        title = songItem.title ?? ""
        album = songItem.albumTitle ?? ""
        persitentID = songItem.persistentID
        artist = songItem.artist ?? ""
        imageUrl = ""
        
        if let art = songItem.artwork?.image(at: CGSize(width: 245.0, height: 268.0)) {
           artwork = art
        } else {
            artwork = UIImage(named: "noAlbumArt.png")!
        }
    }
    
    static func newSongFromMPItemArray(itemArr: [MPMediaItem]) -> [Song]{
        var songArr = [Song]()
        for item in itemArr {
            songArr.append(Song(songItem: item))
        }
       return songArr
    }
}

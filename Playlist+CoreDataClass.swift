//
//  Playlist+CoreDataClass.swift
//  Fast Playist Maker
//
//

import Foundation
import CoreData
import MediaPlayer


public class Playlist: NSManagedObject {

    @objc convenience init(title: String, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Playlist", in: context) {
            self.init(entity: entity, insertInto: context)
            self.name = title
        } else {
            fatalError("could not get entity name")
        }
    }
    
    @objc func playSongsFromPlaylist(controller: MPMusicPlayerController) {
        
        if let songArray = songQuery() {
            
            let collection = MPMediaItemCollection(items: songArray)
            
            controller.setQueue(with: collection)
            controller.prepareToPlay()
            controller.play()
            
        }
        
        
    }
    
    private func songQuery() ->[MPMediaItem]? {
        
        var arr = [MPMediaItem]()
        
        guard let songs = self.savedSong?.allObjects as? [SavedSong] else {
            return nil
        }
        
        for song in songs {
            let query = MPMediaQuery.songs()
            let songPredicate = MPMediaPropertyPredicate(value: song.title, forProperty: MPMediaItemPropertyTitle)
            query.addFilterPredicate(songPredicate)
            
            if let result = query.items?.first {
                arr.append(result)
            }
        }
        return arr
        
    }
    
    
}

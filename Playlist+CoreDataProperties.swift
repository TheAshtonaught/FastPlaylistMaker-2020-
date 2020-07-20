//
//  Playlist+CoreDataProperties.swift
//  Fast Playist Maker
//
//

import Foundation
import CoreData


extension Playlist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Playlist> {
        return NSFetchRequest<Playlist>(entityName: "Playlist");
    }

    @NSManaged public var name: String?
    @NSManaged public var savedSong: NSSet?

}

// MARK: Generated accessors for savedSong
extension Playlist {

    @objc(addSavedSongObject:)
    @NSManaged public func addToSavedSong(_ value: SavedSong)

    @objc(removeSavedSongObject:)
    @NSManaged public func removeFromSavedSong(_ value: SavedSong)

    @objc(addSavedSong:)
    @NSManaged public func addToSavedSong(_ values: NSSet)

    @objc(removeSavedSong:)
    @NSManaged public func removeFromSavedSong(_ values: NSSet)

}

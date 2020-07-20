//
//  SavedSong+CoreDataProperties.swift
//  Fast Playist Maker
//
//

import Foundation
import CoreData


extension SavedSong {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedSong> {
        return NSFetchRequest<SavedSong>(entityName: "SavedSong");
    }

    @NSManaged public var albumImg: NSData?
    @NSManaged public var title: String?
    @NSManaged public var albumTitle: String?
    @NSManaged public var id: Int64
    @NSManaged public var playlist: Playlist?

}

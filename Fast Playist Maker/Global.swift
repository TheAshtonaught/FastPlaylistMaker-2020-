//
//  Global.swift
//  Fast Playist Maker
//
//

import Foundation

class Global {
    var appleMusicPicks: [Song]? = nil
    var showExplainer: Bool? = nil
    var currentPlaylist: Playlist? = nil
    
    
    static var sharedInstance = Global()
    class func sharedClient() -> Global {
        return sharedInstance
    }
}

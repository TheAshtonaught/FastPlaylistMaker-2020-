//
//  PlaylistCheetahTests.swift
//  PlaylistCheetahTests
//
//  Created by Ashton Morgan on 7/14/20.
//  Copyright © 2020 Ashton Morgan. All rights reserved.
//

import XCTest
@testable import Playlist_Cheetah
@testable import Firebase

class PlaylistCheetahTests: XCTestCase {

    // TEST: parse playlist from Dynamic link
    func testDynamicLinkParsing() {
        
        let link = URL(string: "https://www.playlistcheetah.com/-MBXJiCxh3-zdzm5BZQT")
        let playlistId = "-MBXJiCxh3-zdzm5BZQT"
        let lastPath = link?.lastPathComponent
        
        
        XCTAssertEqual(playlistId, lastPath, "Was not able to parse playlist Id")
    }
    
    func testRetrievePlaylistFromFirebase() {
        let playlistId = "-MBXJiCxh3-zdzm5BZQT"
        let playlistTitle = "GTFFF"
        let ref = Database.database().reference()
        
        ref.child(playlistId).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            let title = value?["PLAYLIST_TITLE"] as? String
            
            
            XCTAssertEqual(playlistTitle, title, "Was not able to get playlist from firebase")
            
        })
        
    }

}

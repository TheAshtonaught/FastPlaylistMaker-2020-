//
//  AppleMusicConstants.swift
//  Fast Playist Maker
//

import Foundation

extension AppleMusicConvenience {
    struct Components {
        static let Scheme = "https"
        static let Host = "itunes.apple.com"
        static let Path = ""
    }
    
    struct parameterKeys {
        static let term = "term"
        static let entity = "entity"
        static let id = "id"
    }
    
    struct jsonResponseKeys {
        static let results = "results"
        static let trackName = "trackName"
        static let artwork = "artworkUrl60"
        static let albumName = "collectionName"
        static let artist = "artistName"
        static let trackId = "trackId"
        static let previewUrl = "previewUrl"
    }
    
    struct ids {
        static let similarSongId: UInt64 = 888
    }
}























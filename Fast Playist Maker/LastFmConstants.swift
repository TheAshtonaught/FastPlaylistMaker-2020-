//
//  LastFmConstants.swift
//  Fast Playist Maker
//
//

import Foundation

extension LastFmConvenience {
    
    struct Components {
        static let Scheme = "https"
        static let Host = "ws.audioscrobbler.com"
        static let Path = "/2.0/"
    }
    
    struct parameterKeys {
        static let method = "method"
        static let artist = "artist"
        static let track = "track"
        static let key = "api_key"
        static let format = "format"
        static let limit = "limit"
    }
    
    struct parameterValues {
        static let method = "track.getsimilar"
        static let key = "37a69d873397ff2ddf0b45bfc9eee63c"
        static let format = "json"
        static let limit = 10
    }
    
    struct jsonResponseKeys {
        static let similarTracks = "similartracks"
        static let track = "track"
        static let name = "name"
        static let artist = "artist"
        static let match = "match"
        
        
    }
    
}

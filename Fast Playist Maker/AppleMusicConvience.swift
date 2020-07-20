//
//  AppleMusicConvience.swift
//  Fast Playist Maker
//
//

import Foundation
import CoreData
import UIKit

class AppleMusicConvenience {
    
    var apiConvenience: ApiConvenience
    
    init() {
        let apiConstants = ApiConstants(scheme: Components.Scheme, host: Components.Host, path: Components.Path, domain: "AppleMusicClient")
        apiConvenience = ApiConvenience(apiConstants: apiConstants)
    }
    
    fileprivate static var sharedInstance = AppleMusicConvenience()
    class func sharedClient() -> AppleMusicConvenience {
        return sharedInstance
    }
    
    fileprivate func appleMusicApiRequest(url: NSURL, method: String, completionHandler: @escaping (_ json: [String:AnyObject]?, _ error: NSError?) -> Void) {
        
        apiConvenience.apiRequest(url: url, method: method, nil) { (data, error) in
            
            if let data = data {
                
                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject] {
                        
                        completionHandler(jsonDict,nil)
                    }
                } catch { return }
                
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    func getSongs(searchTerm: String, completionHandler: @escaping (_ songDictArr: [[String : AnyObject]]?, _ error: NSError?) -> Void) {
        
        let parameters: [String:Any] = [parameterKeys.term: "\(searchTerm)",
            parameterKeys.entity: "song",
            "limit": 10
        ]
        
        let songUrl = apiConvenience.apiUrlForMethod(method: nil, PathExt: "/search", parameters: parameters as [String : AnyObject]?)
        
        appleMusicApiRequest(url: songUrl, method: "GET") { (jsonDict, error) in
            
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            
            if let dict = jsonDict, let songResults = dict["results"] as? [[String:AnyObject]] {
                completionHandler(songResults, nil)
            } else {
                completionHandler(nil, self.apiConvenience.errorReturn(code: 0, description: "No song found", domain: "AMApi"))
            }
        }
        
    }
    
    func getSong(trackId: String, completionHandler: @escaping (_ songDictArr: [[String : AnyObject]]?, _ error: NSError?) -> Void) {
        
        let parameters: [String:Any] = [parameterKeys.id: "\(trackId)",
            parameterKeys.entity: "song",
            "limit": 2
        ]
        
        let songUrl = apiConvenience.apiUrlForMethod(method: nil, PathExt: "/lookup", parameters: parameters as [String : AnyObject]?)
        
        appleMusicApiRequest(url: songUrl, method: "GET") { (jsonDict, error) in
            
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            
            if let dict = jsonDict, let songResults = dict["results"] as? [[String:AnyObject]] {
                completionHandler(songResults, nil)
            } else {
                completionHandler(nil, self.apiConvenience.errorReturn(code: 0, description: "No song found", domain: "AMApi"))
            }
        }
        
    }
    
    func cancelSearch() {
        self.apiConvenience.dropAllTask(apiConstants: ApiConstants(scheme: Components.Scheme, host: Components.Host, path: Components.Path, domain: "AppleMusicClient"))
    }
    
    func addSong(searchTerm: String, completion: @escaping (_ song: Song?) -> Void) {
                
        getSongs(searchTerm: searchTerm) { (songDict, error) in
            
            guard error == nil else { return }
            
            if let dict = songDict {
                var title: String!
                var albumTitle: String!
                //var artwork: UIImage
                var id: String!
                var artist: String!
                var trackId: Int!
                var previewUrl: String!
                
                //if dict.count > 1 {
                
                if let songRow = dict.first {
                    
                    if let urlString = songRow[AppleMusicConvenience.jsonResponseKeys.artwork] as? String {
                        
                        title = songRow[AppleMusicConvenience.jsonResponseKeys.trackName] as? String
                        albumTitle = songRow[AppleMusicConvenience.jsonResponseKeys.albumName] as? String
                        trackId = songRow[AppleMusicConvenience.jsonResponseKeys.trackId] as? Int
                        previewUrl = songRow[AppleMusicConvenience.jsonResponseKeys.previewUrl] as? String
                        
                        
                        id = String(songRow["trackId"] as! Int)
                        artist = songRow[AppleMusicConvenience.jsonResponseKeys.artist] as? String
                        
                        let song = Song(imageUrl: urlString, trackId: trackId, previewUrl: previewUrl, artwork: #imageLiteral(resourceName: "noAlbumArt"), title: title, album: albumTitle, id: UInt64(id)!, artist: artist)
                        
                        
                        completion(song)
                        
                    }
                    
                }
            }
            
        }
        
    }
    
    func addSong(fromTrackId trackId: String, completion: @escaping (_ song: Song?) -> Void) {
        
        getSong(trackId: trackId) { (songDict, error) in
            
            guard error == nil else { return }
            
            if let dict = songDict {
                var title: String!
                var albumTitle: String!
                //var artwork: UIImage
                var id: String!
                var artist: String!
                var trackId: Int!
                var previewUrl: String!
                
                //if dict.count > 1 {
                
                if let songRow = dict.first {
                    
                    if let urlString = songRow[AppleMusicConvenience.jsonResponseKeys.artwork] as? String {
                        
                        title = songRow[AppleMusicConvenience.jsonResponseKeys.trackName] as? String
                        albumTitle = songRow[AppleMusicConvenience.jsonResponseKeys.albumName] as? String
                        trackId = songRow[AppleMusicConvenience.jsonResponseKeys.trackId] as? Int
                        previewUrl = songRow[AppleMusicConvenience.jsonResponseKeys.previewUrl] as? String
                        
                        
                        id = String(songRow["trackId"] as! Int)
                        artist = songRow[AppleMusicConvenience.jsonResponseKeys.artist] as? String
                        
                        let song = Song(imageUrl: urlString, trackId: trackId, previewUrl: previewUrl, artwork: #imageLiteral(resourceName: "noAlbumArt"), title: title, album: albumTitle, id: UInt64(id)!, artist: artist)
                        
                        
                        completion(song)
                        
                    }
                    
                }
            }
            
        }
        
    }
    
    func addSimilarSongToLibrary(similarSong: Song, completion: @escaping (_ song: Song?) -> Void) {
        
        let searchTerm = "\(similarSong.title) \(similarSong.artist)"
        
        getSongs(searchTerm: searchTerm) { (songDict, error) in
            
            guard error == nil else { return }
            
            if let dict = songDict {
                var title: String!
                var albumTitle: String!
                var artwork: UIImage
                var id: String!
                var artist: String!
                
                
                
                //if dict.count > 1 {
                    
                if let songRow = dict.first {
                
                    if let urlString = songRow[AppleMusicConvenience.jsonResponseKeys.artwork] as? String,
                    let imgUrl = URL(string: urlString),
                    let imgData = NSData(contentsOf: imgUrl) {
                    title = songRow[AppleMusicConvenience.jsonResponseKeys.trackName] as? String
                    albumTitle = songRow[AppleMusicConvenience.jsonResponseKeys.albumName] as? String
                    artwork = UIImage(data: imgData as Data) ?? UIImage(named: "noAlbumArt.png")!
                    id = String(songRow["trackId"] as! Int)
                    artist = songRow[AppleMusicConvenience.jsonResponseKeys.artist] as? String
                        
                    //let songII = Song(imageUrl: urlString, artwork: #imageLiteral(resourceName: "noAlbumArt"), title: title, album: albumTitle, id: UInt64(id)!, artist: artist)
                        
                    let song = Song(artwork: artwork, title: title, album: albumTitle, id: UInt64(id)!, artist: artist)
                    
                    completion(song)
                    
                }
                
            }
            }
                
        }
            
    }
    
    
    
        
}
    
    
    
    
    












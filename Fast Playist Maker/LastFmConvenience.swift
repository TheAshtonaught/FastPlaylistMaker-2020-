//
//  LastFmConvenience.swift
//  Fast Playist Maker
//
//

import Foundation
import UIKit

class LastFmConvenience {
    
    let apiConvenience: ApiConvenience
    var appleMusicClient = AppleMusicConvenience.sharedClient()
    
    init() {
        let apiConstants = ApiConstants(scheme: Components.Scheme, host: Components.Host, path: Components.Path, domain: "LastFmClient")
        apiConvenience = ApiConvenience(apiConstants: apiConstants)
    }
    
    fileprivate static var sharedInstance = LastFmConvenience()
    class func sharedClient() -> LastFmConvenience {
        return sharedInstance
    }
    
    fileprivate func lastFmApiRequest(url: NSURL, method: String, completionHandler: @escaping (_ json: [String:AnyObject]?, _ error: NSError?) -> Void) {
        
        apiConvenience.apiRequest(url: url, method: method, nil) { (data, error) in
            
            if let data = data {
        //TODO: Make json serialization safe
                let jsonDict = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                
                completionHandler(jsonDict,nil)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    
    
    func getSimilarSongs(song: Song, completionHandler: @escaping (_ similarSongs: [SimilarSong]?, _ error: NSError?) -> Void) {
        
        var songArray = [SimilarSong]()
        
            let parameters: [String:Any] = [
                parameterKeys.method: parameterValues.method,
                parameterKeys.artist: song.artist,
                parameterKeys.key: parameterValues.key,
                parameterKeys.track: song.title,
                parameterKeys.format: parameterValues.format,
                parameterKeys.limit: parameterValues.limit]
            
            let url = apiConvenience.apiUrlForMethod(method: nil, PathExt: nil, parameters: parameters as [String : AnyObject]?)
            //print(url)
            
            lastFmApiRequest(url: url, method: "GET") { (jsonDict, error) in
                
                guard error == nil else {
                    completionHandler(nil, error)
                    return
                }
                
                if let dict = jsonDict, let songResults = dict["similartracks"] as? [String:AnyObject], let similars = songResults["track"] as? [[String: AnyObject]] {
                    for sim in similars {
                        
                        if let name = sim[jsonResponseKeys.name] as? String, let match = sim[jsonResponseKeys.match] as? Double, let imageDict = sim["image"] as? [[String: AnyObject]], let artistDict = sim["artist"] as? [String:AnyObject], let artist = artistDict["name"] as? String {
                            
                            
                            var imageString: String!
                            
                            for image in imageDict {
                                if image["size"] as? String == "extralarge" {
                                    if let imageUrl = image["#text"] as? String {
                                       imageString = imageUrl
                                    }
                                }
                            }

                            if let imageUrl = URL(string: imageString) {
                                
                                let song = SimilarSong(withMatch: match, imageUrl: imageUrl, title: name, id: AppleMusicConvenience.ids.similarSongId, artist: artist)
                                
                                songArray.append(song)
                            }
                        }
                    }
                }
                
                completionHandler(songArray, nil)
            }
    }
    
    func stopTask() {
        self.apiConvenience.dropAllTask(apiConstants: ApiConstants(scheme: Components.Scheme, host: Components.Host, path: Components.Path, domain: "LastFmClient"))
    }
}

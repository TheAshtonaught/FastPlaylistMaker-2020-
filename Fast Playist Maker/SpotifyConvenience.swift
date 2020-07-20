//
//  SpotifyConvenience.swift
//  Fast Playist Maker
//
//

import Foundation
import UIKit

class SpotifyClient {
    var apiConvenience: ApiConvenience
    var apiConstants: ApiConstants
    let CLIENT_ID = "c619a26ce125472d9a84c4eb5b5a4206"
    let CLIENT_SECRET = "3ce745e972ac41cca2ca2bc84caadcdb"
    let REDIRECT_URI = "cheetah://"
    let SCOPES = ["playlist-read-private", "playlist-read-collaborative", "playlist-modify-public", "playlist-modify-private"]
    var encodedScopes: String {
        return SCOPES.joined(separator: "%20")
    }
    
    init() {
        apiConstants = ApiConstants(scheme: Components.Scheme, host: Components.Host, path: Components.Path, domain: "SpotifyMusicClient")
        apiConvenience = ApiConvenience(apiConstants: apiConstants)
    }
    
    fileprivate static var sharedInstance = SpotifyClient()
    class func sharedClient() -> SpotifyClient {
        return sharedInstance
    }
    
    func loginToSpotify() {
        
        let urlString = "https://accounts.spotify.com/authorize?client_id=\(CLIENT_ID)&response_type=code&redirect_uri=\(REDIRECT_URI)&scope=\(encodedScopes)"
        if let url = URL(string: urlString) {
            let app = UIApplication.shared
            
            if app.canOpenURL(url) {
                app.open(url)
            }
        }
    }
    
    func spotifyTokenRequest(code: String) {
        
        let parameters: [String:Any] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": REDIRECT_URI,
            "client_id": CLIENT_ID,
            "client_secret": CLIENT_SECRET
        ]
        
        let idandSecret = "\(CLIENT_ID):\(CLIENT_SECRET)".toBase64()
        
        
        let headers = ["Authorization":"Basic \(idandSecret)", "Accept": "application/json", "Content-Type": "application/x-www-form-urlencoded"]
        
        let tokenUrl = apiConvenience.buildSpotifyTokenRequestUrl(method: nil, PathExt: nil, parameters: parameters as [String : AnyObject])
        //print(tokenUrl)
        
        apiConvenience.apiRequest(url: tokenUrl, method: "POST", headers) { (data, error) in
            
            if let data = data {
                
                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject] {
                        
                        guard let token = jsonDict["access_token"] as? String else{
                            return
                        }
                        let tokenDict: [String: Any] = ["token": token]
                        
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "receivedSpotifyToken"), object: nil, userInfo: tokenDict)
                        
                    }
                } catch { return }
                
            }
        
        }
    }
    
    
    func getSpotifyTrackId(token: String, query: String, completionHandler: @escaping (_ spotifyTrackId: String?) -> Void) {
        var idString: String?
        
        let params: [String: Any] = ["q": query, "type": "track", "limit": 1]
        
        let headers = ["Authorization":"Bearer \(token)", "Accept": "application/json", "Content-Type": "application/x-www-form-urlencoded"]
        
        let searchUrl = apiConvenience.apiUrlForMethod(method: nil, PathExt: "search", parameters: params as [String : AnyObject])
        
        apiConvenience.apiRequest(url: searchUrl, method: "GET", headers) { (data, error) in
            
            if let data = data {
                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject] {
                        
                        if let trackDict = jsonDict["tracks"] as? [String: AnyObject], let items = trackDict["items"] as? [[String: AnyObject]], let songResult = items.first, let id = songResult["uri"] as? String {
                            idString = id
                        }
                        
                    }
                } catch { return }
                
            }
            
           completionHandler(idString)
        }
        
    }
    
    func createSpotifyPlaylist(token: String, uID: String, playlistName: String, completion: @escaping (_ playlistId: String?) -> Void) {
        
        let body: [String: AnyObject] = ["name": playlistName as AnyObject]
        
        let headers = ["Authorization":"Bearer \(token)", "Accept": "application/json", "Content-Type": "application/x-www-form-urlencoded"]
        
        let cspUrl = apiConvenience.apiUrlForMethod(method: nil, PathExt: "users/\(uID)/playlists", parameters: nil)
        
        apiConvenience.apiRequest(withJsonBody:body, url: cspUrl, method: "POST", headers) { (data, error) in
            
            if let data = data {
                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                        
                        //getPlaylistId
                        
                        if let id = jsonDict["id"] as? String{
                            completion(id)
                        }
                    }
                } catch { return }
            }
        }
    }
    
    func getUserId(token: String, completion: @escaping (_ uId: String?) -> Void) {
        
        let headers = ["Authorization":"Bearer \(token)", "Accept": "application/json", "Content-Type": "application/x-www-form-urlencoded"]
        
        let userUrl = apiConvenience.apiUrlForMethod(method: nil, PathExt: "me", parameters: nil)
        
        apiConvenience.apiRequest(url: userUrl, method: "GET", headers) { (data, error) in
            
            if let data = data {
                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                        
                        if let id = jsonDict["id"] as? String{
                            completion(id)
                        }
                        
                    }
                } catch { return }
            }
            
        }
        
    }
    
    
    func addTracksToSpotifyPlaylist(trackIds: [String],userID: String, playlistId: String, token: String) {
        
        let headers = ["Authorization":"Bearer \(token)", "Accept": "application/json", "Content-Type": "application/x-www-form-urlencoded"]
        
//        let jsonBody: [String: Any] = ["uri": [trackIds]]
        
        let body = ["uris": trackIds]
        
        let addTracksUrl = apiConvenience.apiUrlForMethod(method: nil, PathExt: "users/\(userID)/playlists/\(playlistId)/tracks", parameters: nil)
        apiConvenience.apiRequest(withJsonBody: body as [String : AnyObject], url: addTracksUrl, method: "POST", headers) { (data, error) in
            
            if let data = data {
                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject] {
                        
//                        print(jsonDict)
                        if let _ = jsonDict["snapshot_id"] {
                            self.getSpotifyPlaylist(playlistId: playlistId, token: token, userId: userID)
                        } else {
                            print("error getting snapshot id")
                        }
                    }
                } catch {return}
            }
        }
    }
    
    func getSpotifyPlaylist(playlistId: String, token: String, userId: String) {
        
        let headers = ["Authorization":"Bearer \(token)", "Accept": "application/json", "Content-Type": "application/x-www-form-urlencoded"]
        
        let params = ["fields": "external_urls,uri"]
        
        let playlistUrl = apiConvenience.apiUrlForMethod(method: nil, PathExt: "users/\(userId)/playlists/\(playlistId)", parameters: params as [String : AnyObject])
        
        apiConvenience.apiRequest(url: playlistUrl, method: "GET", headers) { (data, _) in
            
            if let data = data {
                
                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                                                
                        if let uri = jsonDict["uri"] as? String, let externalUrlDict = jsonDict["external_urls"] as? [String: AnyObject], let webURL = externalUrlDict["spotify"] as? String {
                            
                            self.openSpotifyPlaylist(fromUri: uri, externalUrl: webURL)
                        }

                    }
                } catch {return}
            }
            
        }

        
    }
    
    func openSpotifyPlaylist(fromUri uri: String, externalUrl: String) {
        if let url = URL(string: uri), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        } else if let href = URL(string: externalUrl), UIApplication.shared.canOpenURL(href) {
            UIApplication.shared.open(href, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        }
    }
    
    func launchSpotifyPlaylist(token: String, spotifyTrakIds: [String], name: String) {
        getUserId(token: token) { (userId) in
            guard let userId = userId else{
                print("error geting user id: launchSpotifyPlaylist(:)")
                return
            }
           self.createSpotifyPlaylist(token: token, uID: userId, playlistName: name, completion: { (playlistId) in
            guard let playlistId = playlistId else{
                print("error getting playlistId createSpotifyPlaylist(:)")
                return
            }
            
            self.addTracksToSpotifyPlaylist(trackIds: spotifyTrakIds, userID: userId, playlistId: playlistId, token: token)
            
           })
            
        }
    }
    
}










// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

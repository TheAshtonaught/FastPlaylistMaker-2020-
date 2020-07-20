//
//  SimilarSong.swift
//  Fast Playist Maker
//
//

import Foundation
import UIKit

struct SimilarSong {
    var imageUrl: URL
    var title: String
    var persitentID: UInt64
    var artist: String
    var match: Double
    var albumImage: UIImage?
    
    init(imageUrl: URL, title: String, id: UInt64, artist: String) {
        self.imageUrl = imageUrl
        self.title = title
        self.persitentID = id
        self.artist = artist
        self.match = 0.0
    }
    
    init(withMatch: Double, imageUrl: URL, title: String, id: UInt64, artist: String) {
        self.imageUrl = imageUrl
        self.title = title
        self.persitentID = id
        self.artist = artist
        self.match = withMatch
    }
    
    func loadImageUsingUrlString() -> UIImage {
        var albumImage: UIImage?
        
        let urlString = self.imageUrl.absoluteString
        let imageUrlString = urlString
        
        guard let url = URL(string: urlString) else {

            return #imageLiteral(resourceName: "noAlbumArt")
        }
        
        if let cachedImage = imageCache.object(forKey: urlString as NSString) as? UIImage {
            albumImage = cachedImage
            
            return albumImage ?? #imageLiteral(resourceName: "noAlbumArt")
        }
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            
            if error != nil {
                print(error!)
                return
            }
            
            DispatchQueue.main.async {
                
                if let data = data, let imageToCache = UIImage(data: data) {
                    
                    if imageUrlString == urlString {
                        
                        albumImage = imageToCache
                    }
                    imageCache.setObject(imageToCache, forKey: urlString as NSString)
                }
            }
        }).resume()
        return albumImage ?? #imageLiteral(resourceName: "noAlbumArt")
    }
    

    
}

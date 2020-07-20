//
//  Extensions.swift
//  Fast Playist Maker
//
//

import Foundation
import UIKit

let imageCache = NSCache<NSString, AnyObject>()


extension UIImageView {
    
    @objc func loadImageUsingCacheWithUniqueString(_ uniqueString: String, imageData: NSData) {
        
        
        self.image = nil
        
        //check cache for image first
        if let cachedImage = imageCache.object(forKey: uniqueString as NSString) as? UIImage {
            self.image = cachedImage
            return
        }
            
        DispatchQueue.main.async(execute: {
                
            if let downloadedImage = UIImage(data: imageData as Data) {
                imageCache.setObject(downloadedImage, forKey: uniqueString as NSString)
                    
                self.image = downloadedImage
            }
        })
            
    }
    
    
    @objc func loadImageUsingUrlString(urlString: String) {
        
        let imageUrlString = urlString
        
        guard let url = URL(string: urlString) else {
            self.image = #imageLiteral(resourceName: "noAlbumArt")
            return
        }
        
        image = nil
        
        if let cachedImage = imageCache.object(forKey: urlString as NSString) as? UIImage {
            self.image = cachedImage
            return
        }
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            
            if error != nil {
                print(error!)
                return
            }
            
            DispatchQueue.main.async {
                
                if let data = data, let imageToCache = UIImage(data: data) {
                    
                    if imageUrlString == urlString {
                        self.image = imageToCache
                    }
                    imageCache.setObject(imageToCache, forKey: urlString as NSString)
                }
                
                
            }
        }).resume()
    }
    
    @objc func addBlurEffect()
    {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.regular)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        blurEffectView.frame = self.bounds
        
        self.addSubview(blurEffectView)
    }
    
}

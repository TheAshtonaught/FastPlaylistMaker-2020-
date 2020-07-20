//
//  LoadingLibraryUI.swift
//  Fast Playist Maker
//
//

import UIKit

class LoadingLibraryUI: UIView {
    
    
    
    @IBOutlet weak var cheetahImage: UIImageView!
    
    
    @objc func cheetahAnimation(animate: Bool) {
        var imgArray = [UIImage]()
        for i in 0...7 {
            imgArray.append(UIImage(named: "cheetah\(i)")!)
        }
        if animate {
            cheetahImage.animationImages = imgArray
            cheetahImage.animationDuration = 0.4
            cheetahImage.startAnimating()
        } else {
            cheetahImage.stopAnimating()
            //self.removeFromSuperview()        
        }
    }
    

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

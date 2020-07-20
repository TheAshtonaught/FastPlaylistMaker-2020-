//
//  DraggableImage.swift
//  Fast Playist Maker
//
//

import UIKit

class DraggableImage: UIImageView {

    override func awakeFromNib() {
        styleImage()
    }
    
    @objc func styleImage() {
        self.superview?.layoutIfNeeded()
        self.clipsToBounds = true
        layer.masksToBounds = true
        layer.cornerRadius = 9.0
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 3)
        self.layer.shadowOpacity = 0.8
        self.layer.shadowRadius = 1.0
        
        
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
}

//
//  Extension+UIimage.swift
//  Fast Playist Maker
//
//

import Foundation
import UIKit

extension UIImage
{
    @objc var highestQualityJPEGNSData: NSData { return self.jpegData(compressionQuality: 1.0)! as NSData }
    @objc var highQualityJPEGNSData: NSData    { return self.jpegData(compressionQuality: 0.75)! as NSData}
    @objc var mediumQualityJPEGNSData: NSData  { return self.jpegData(compressionQuality: 0.5)! as NSData }
    @objc var lowQualityJPEGNSData: NSData     { return self.jpegData(compressionQuality: 0.25)! as NSData}
    @objc var lowestQualityJPEGNSData: NSData  { return self.jpegData(compressionQuality: 0.0)! as NSData }
}















//
//  BorderedButton.swift
//  Fast Playist Maker
//
//

import UIKit

class BorderedButton: UIButton {

    override func awakeFromNib() {
        layer.cornerRadius = 15
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.cgColor
    }

}

//
//  CardContainer.swift
//  Koloda
//
//

import UIKit

class CardContainer: UIView {

    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var albumTitleLabel: UILabel!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupCardContainerView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupCardContainerView()
        
    }
    
    @objc func setupCardContainerView() {
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    func setWithSong(song: Song) {
        
            self.albumImageView.image = song.artwork
            self.songTitleLabel.text = song.title
            self.albumTitleLabel.text = song.artist
        
    }
    
    
    
    func setWithSong(similarSong: SimilarSong) {
        
        let albumUrl = similarSong.imageUrl.absoluteString
        self.albumImageView.loadImageUsingUrlString(urlString: albumUrl)
        self.songTitleLabel.text = similarSong.title
        self.albumTitleLabel.text = similarSong.artist
        
        
    }
    
    
}

//
//  AlbumCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Kemal Kaynak on 06.07.20.
//  Copyright © 2020 Kemal Kaynak. All rights reserved.
//

import UIKit

class AlbumCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.image = UIImage(named: "placeholder")
    }
}

//
//  PhotosSearchResponse.swift
//  Virtual Tourist
//
//  Created by Kemal Kaynak on 06.07.20.
//  Copyright © 2020 Kemal Kaynak. All rights reserved.
//

import Foundation

struct PhotosSearchResponse: Codable {
    let photos: PhotoModel
    let stat: String
}

//
//  Photos.swift
//  Virtual Tourist
//
//  Created by Kemal Kaynak on 06.07.20.
//  Copyright © 2020 Kemal Kaynak. All rights reserved.
//

import Foundation

struct PhotoResponse: Codable {
    let photos: PhotoModel
}

struct PhotoModel: Codable {
    let page: Int
    let pages: Int
    let perPage: Int
    let total: String
    let photo: [PhotoData]

    enum CodingKeys: String, CodingKey {
        case perPage = "perpage"
        case page, pages, total, photo
    }
}

struct PhotoData: Codable {
    let imageURL: String
    enum CodingKeys: String, CodingKey {
        case imageURL = "url_m"
    }
}

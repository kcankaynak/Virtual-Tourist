//
//  MapModel.swift
//  Virtual Tourist
//
//  Created by Kemal Kaynak on 06.07.20.
//  Copyright © 2020 Kemal Kaynak. All rights reserved.
//

import Foundation

struct MapModel: Codable {
    let mapData: MapData
}

struct MapData: Codable {
    let latitude: Double
    let longitude: Double
    let latitudeDelta: Double
    let longitudeDelta: Double
}

//
//  UserData.swift
//  Virtual Tourist
//
//  Created by Kemal Kaynak on 06.07.20.
//  Copyright © 2020 Kemal Kaynak. All rights reserved.
//

import Foundation
import MapKit

struct UserData {
    
    private enum Keys: String {
        case userRegion = "userRegion"
    }
    
    private static let userDefaults = UserDefaults.standard
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()
    
    static func fetchLastLocation() -> MKCoordinateRegion? {
        guard let mapRegion = userDefaults.object(forKey: UserData.Keys.userRegion.rawValue) as? Data,
                let mapModel = try? decoder.decode(MapModel.self, from: mapRegion) else { return nil }
        let center = CLLocationCoordinate2D(latitude: mapModel.mapData.latitude, longitude: mapModel.mapData.longitude)
        let span = MKCoordinateSpan(latitudeDelta: mapModel.mapData.latitudeDelta, longitudeDelta: mapModel.mapData.longitudeDelta)
        return MKCoordinateRegion(center: center, span: span)
    }
    
    static func saveLastLocation(_ region: MKCoordinateRegion) {
        let mapModel = MapModel(mapData: MapData(latitude: region.center.latitude, longitude: region.center.longitude, latitudeDelta: region.span.latitudeDelta, longitudeDelta: region.span.longitudeDelta))
        guard let mapData = try? encoder.encode(mapModel) else { return }
        userDefaults.set(mapData, forKey: UserData.Keys.userRegion.rawValue)
    }
}

//
//  BaseService.swift
//  Virtual Tourist
//
//  Created by Kemal Kaynak on 06.07.20.
//  Copyright © 2020 Kemal Kaynak. All rights reserved.
//

import Foundation

final class BaseService {
    
    static let shared = BaseService()
    
    private static let apiKey = "372ea388feb412015551567f06d45eae"
    private static let decoder = JSONDecoder()
    
    enum Endpoints {
        static let baseURL = "https://www.flickr.com/services/rest/?method="
        
        case searchPhotos(latitude:Double, longitude:Double)
        
        var stringURL: String {
            switch self {
            case let .searchPhotos(latitude, longitude):
                return Endpoints.baseURL + "flickr.photos.search&" + "api_key=\(apiKey)&" + "sort=date-posted-asc&" +
                    "&privacy_filter=1" + "media=photos&" + "lat=\(latitude)&lon=\(longitude)&" + "extras=url_m&" + "per_page=21&" + "page=\(Int.random(in: 1...25))&" + "format=json&nojsoncallback=1"
            }
        }
        var url: URL {
            return URL(string: stringURL)!
        }
    }
}

// MARK: - Requests -

extension BaseService {
    
    func searchPhotos(lat: Double, lon: Double, completionHandler: @escaping (PhotoResponse?, Error?) -> Void ) {
        URLSession.shared.dataTask(with: Endpoints.searchPhotos(latitude: lat, longitude: lon).url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            do {
                let responseObject = try BaseService.decoder.decode(PhotoResponse.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(responseObject, nil)
                }
            }
            catch {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
        }.resume()
    }
    
    func downloadImage(imageURL: URL, completionHandler: @escaping (Data?, Error?) -> Void ){
        URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            DispatchQueue.main.async {
                completionHandler(data, nil)
            }
        }.resume()
    }
}

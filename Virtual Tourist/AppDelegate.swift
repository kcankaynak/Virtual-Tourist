//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Kemal Kaynak on 05.07.20.
//  Copyright © 2020 Kemal Kaynak. All rights reserved.
//

import UIKit
import CoreData
import MapKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var lastRegion: MKCoordinateRegion!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        CoreDataController.shared.load()
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        UserData.saveLastLocation(lastRegion)
        CoreDataController.shared.save()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        UserData.saveLastLocation(lastRegion)
        CoreDataController.shared.save()
    }
}


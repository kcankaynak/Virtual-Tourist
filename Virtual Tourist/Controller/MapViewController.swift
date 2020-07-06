//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Kemal Kaynak on 05.07.20.
//  Copyright © 2020 Kemal Kaynak. All rights reserved.
//

import UIKit
import CoreData
import MapKit

let appDel = UIApplication.shared.delegate as! AppDelegate

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    fileprivate let imageRect = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 140)
    fileprivate var snapshotImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchResult()
        setupMap()
        setupRecognizer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchResult()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let albumVC = segue.destination as? AlbumViewController, let selectedPin = sender as? Pin else { return }
        albumVC.headerImage = snapshotImage
        albumVC.selectedPin = selectedPin
    }
}

// MARK: - Setup Map -

extension MapViewController {
    
    fileprivate func setupMap() {
        if let lastRegion = UserData.fetchLastLocation() {
            mapView.setRegion(lastRegion, animated: true)
        }
        if let pins = fetchedResultsController.fetchedObjects {
            setupAnnotations(pins)
        }
    }
}

// MARK: - Setup Fetch Result -

extension MapViewController {
    
    fileprivate func setupFetchResult() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        try? fetchedResultsController.performFetch()
    }
}

// MARK: - Setup Recognizer -

extension MapViewController {
    
    fileprivate func setupRecognizer() {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(recognizer)
    }
}

// MARK: - Map View Delegate -

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: AppIdentifiers.Reuse.pin) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: AppIdentifiers.Reuse.pin)
            pinView!.animatesDrop = true
            pinView!.canShowCallout = true
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        guard let pinCoordinate = view.annotation?.coordinate,
                let pins = fetchedResultsController.fetchedObjects,
                let selectedPin = pins.first(where: { $0.latitude == pinCoordinate.latitude && $0.longitude == pinCoordinate.longitude }) else { return }
        takeSnapshot(selectedPin)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        appDel.lastRegion = mapView.region
    }
}

// MARK: - Handle Long Press -

extension MapViewController {
    
    @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            let location = recognizer.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)

            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            mapView.setCenter(mapView.centerCoordinate, animated: true)

            let pin = Pin(context: CoreDataController.shared.viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude

            CoreDataController.shared.save()
            try? fetchedResultsController.performFetch()
        }
    }
}

// MARK: - Create Map Snapshot -

extension MapViewController {
    
    fileprivate func takeSnapshot(_ pin: Pin) {
        let snapOptions = MKMapSnapshotter.Options()
        snapOptions.region = mapView.region
        snapOptions.scale = UIScreen.main.scale
        snapOptions.size = imageRect.size
        
        let snapshot = MKMapSnapshotter(options: snapOptions)
        snapshot.start { snapshot, error in
            guard let snapshot = snapshot, error == nil else { return }

            let image = UIGraphicsImageRenderer(size: snapOptions.size).image { _ in
                snapshot.image.draw(at: .zero)

                let pinView = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
                let pinImage = pinView.image
                var point = snapshot.point(for: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
                if self.imageRect.contains(point) {
                    point.x -= pinView.bounds.width / 2
                    point.y -= pinView.bounds.height / 2
                    point.x += pinView.centerOffset.x
                    point.y += pinView.centerOffset.y
                    pinImage?.draw(at: point)
                }
            }
            self.snapshotImage = image
            self.performSegue(withIdentifier: AppIdentifiers.Segue.showAlbum, sender: pin)
        }
    }
}

// MARK: - Create Annotation -

extension MapViewController {
    
    func setupAnnotations(_ pins: [Pin]) {
        var annotations = [MKPointAnnotation]()
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
            annotations.append(annotation)
        }
        DispatchQueue.main.async {
            self.mapView.addAnnotations(annotations)
        }
    }
}

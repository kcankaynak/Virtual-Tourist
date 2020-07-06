//
//  AlbumCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Kemal Kaynak on 06.07.20.
//  Copyright © 2020 Kemal Kaynak. All rights reserved.
//

import UIKit
import CoreData

class AlbumViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    var selectedPin: Pin!
    var headerImage: UIImage!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var isRemoveAllData = false
    
    private let dispatchGroup = DispatchGroup()
    fileprivate lazy var  activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        indicator.color = .lightGray
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    let space: CGFloat = 2.0
    lazy var collectionSize: CGSize = {
        return CGSize(width: (view.frame.size.width - (2 * space)) / 3, height: (view.frame.size.width - (2 * space)) / 3)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Photos"
        setupFetchedResultsController()
        fetchPhotos()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    private func setupNavigationBar() {
        let barButton = UIBarButtonItem(customView: activityIndicator)
        navigationItem.setRightBarButton(barButton, animated: true)
    }
    
    deinit {
        fetchedResultsController = nil
    }
}

// MARK: - Setup Fetch Result Controller -

extension AlbumViewController {
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", selectedPin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
    }
}

// MARK: - Fetch Photos -

extension AlbumViewController {
    
    fileprivate func fetchPhotos() {
        if fetchedResultsController.fetchedObjects == nil || fetchedResultsController.fetchedObjects!.isEmpty {
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
            }
            newCollectionButton.isEnabled = false
            BaseService.shared.searchPhotos(lat: selectedPin.latitude, lon: selectedPin.longitude) { (response, error) in
                if let response = response {
                    self.downloadPhotos(response.photos)
                } else {
                    self.showError(error?.localizedDescription ?? "Unexpected error occured")
                }
            }
        }
    }
    
    fileprivate func downloadPhotos(_ model: PhotoModel) {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
        }
        for photo in model.photo {
            dispatchGroup.enter()
            let photoObject = Photo(context: CoreDataController.shared.viewContext)
            photoObject.pin = selectedPin
            if let photoURL = URL(string: photo.imageURL) {
                BaseService.shared.downloadImage(imageURL: photoURL) { (data, error) in
                    if let data = data {
                        photoObject.image = data
                        CoreDataController.shared.save()
                    }
                    self.dispatchGroup.leave()
                }
            } else {
                setupPlaceholder(photoObject)
            }
        }
        dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            self.activityIndicator.stopAnimating()
            self.isRemoveAllData = false
            self.newCollectionButton.isEnabled = true
            self.collectionView.performBatchUpdates({
                self.collectionView.reloadSections(IndexSet(integer: 0))
            }, completion: nil)
        })
    }
        
    fileprivate func setupPlaceholder(_ photoObject: Photo) {
        if let placeholderData = UIImage(named: "placeholder")?.pngData() {
            photoObject.image = placeholderData
        }
    }
}

// MARK: - New Action -

extension AlbumViewController {
    
    @IBAction func newAction(_ sender: Any) {
        isRemoveAllData = true
        newCollectionButton.isEnabled = false
        if let fetchedObject = fetchedResultsController.fetchedObjects {
            for object in fetchedObject {
                CoreDataController.shared.delete(object)
            }
        }
        BaseService.shared.searchPhotos(lat: selectedPin.latitude, lon: selectedPin.longitude) { (response, error) in
            if let response = response {
                self.downloadPhotos(response.photos)
            } else {
                self.showError(error?.localizedDescription ?? "Unexpected error occured")
            }
        }
    }
}

// MARK: - UICollectionView Data Source -

extension AlbumViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let albumCell = collectionView.dequeueReusableCell(withReuseIdentifier: AppIdentifiers.Reuse.albumCell, for: indexPath) as? AlbumCollectionViewCell else { return UICollectionViewCell() }
        if let photoData = fetchedResultsController.object(at: indexPath).image {
            albumCell.imageView.image = UIImage(data: photoData)
        } else {
            albumCell.imageView.image = UIImage(named: "placeholder")
        }
        return albumCell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let reusableView = UICollectionReusableView()
        if kind == UICollectionView.elementKindSectionHeader, let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: AppIdentifiers.Reuse.albumHeader, for: indexPath) as? AlbumCollectionHeaderView {
            headerView.headerImageView.image = headerImage
            return headerView
        }
        return reusableView
    }
}

// MARK: - UICollectionView Delegate -

extension AlbumViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showAlert(indexPath)
    }
}

// MARK: - UICollectionFlowLayout Delegate -
extension AlbumViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return space
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return space
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
}

// MARK: - Fetch Result Delegate -

extension AlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let indexPath = indexPath, type == .delete, !isRemoveAllData {
            collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [indexPath])
            }, completion: { finished in
                if finished {
                    self.fetchPhotos()
                }
            })
        }
    }
}

// MARK: - Show Error -

extension AlbumViewController {
    
    fileprivate func showError(_ message: String) {
        let alertController = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func showAlert(_ indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Warning", message: "Are you sure to delete this item?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
            let object = self.fetchedResultsController.object(at: indexPath)
            CoreDataController.shared.delete(object)
            CoreDataController.shared.save()
        }))
        present(alertController, animated: true, completion: nil)
    }
}

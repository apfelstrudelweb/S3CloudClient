//
//  ViewController.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 01.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import UIKit
import CoreData

let cellReuseIdentifier = "elementCell"

class ViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private let persistencyManager = PersistencyManager()
    private let fileHandler = FileHandler()
    private let refreshControl = UIRefreshControl()
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Element> = {
        
        let fetchRequest = NSFetchRequest<Element> (entityName: "Element")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: persistencyManager.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //LibraryAPI.shared.clearDB()  // for test purposes only
        
        tableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: cellReuseIdentifier)
        self.tableView.tableFooterView = UIView(frame: .zero)
        self.tableView.rowHeight = 90.0
        self.tableView.estimatedRowHeight = 90.0
        self.tableView.allowsSelection = false
        self.tableView.delegate = self
        
        if #available(iOS 10.0, *) {
            self.tableView.refreshControl = refreshControl
        } else {
            self.tableView.addSubview(refreshControl)
        }
        
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        fetchRemoteData()
    }
    
    fileprivate func fetchRemoteData() {
        
        // do expensive operations in the background thread in order to not block the GUI meanwhile
        DispatchQueue.global(qos: .background).async {
            
            do {
                try LibraryAPI.shared.updateCoreDataWithJSON()
                try LibraryAPI.shared.downloadAssets()
                try LibraryAPI.shared.processFingerprints()
                print("**************** remote data fetched ****************")
                try self.fetchedResultsController.performFetch()
                DispatchQueue.main.async {
                    // GUI staff only in the main thread!
                    self.tableView.reloadData()
                }
            } catch {
                print(error)
                displayAlert(message: error.legibleDescription)
            }
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        
        self.fetchRemoteData()
        self.refreshControl.endRefreshing()
        
    }
    
    
}

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let objects = fetchedResultsController.fetchedObjects {
            return objects.count
        }
        return 0
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! TableViewCell
        
        let element = fetchedResultsController.object(at: indexPath)
        guard let assetPNG: Asset = element.assets!.first(where: { ($0 as! Asset).type == AssetType.png.rawValue }) as? Asset, let relativeFilePath = assetPNG.relativeFilePath else {
            return cell
        }
        
        let fileURL = fileHandler.getAbsolutePathURL(from: relativeFilePath)
        
        if let imageData = NSData(contentsOf: fileURL) {
            let image = assetPNG.isCorrupt ? UIImage(named: "placeholder") : UIImage(data: imageData as Data)
            cell.videoImageView.image = image
        } else {
            cell.videoImageView.image = UIImage(named: "placeholder")
        }
        
        cell.videoLabel.text = element.fileName
        
        return cell
    }
    
    // reset images from reusable cell after scroll -> otherwise we get glitches
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as! TableViewCell).videoImageView.image = nil
    }
}

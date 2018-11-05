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

class ViewController: UIViewController, VideoCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private let persistencyManager = PersistencyManager.shared
    private let libraryAPI = LibraryAPI.shared
    
    
    private let fileHandler = FileHandler()
    private let refreshControl = UIRefreshControl()
    
    fileprivate lazy var fetchedResultsControllerElement: NSFetchedResultsController<Element> = {
        
        let fetchRequest = NSFetchRequest<Element> (entityName: "Element")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "previewImagePresent == true") // otherwise it doesn't make sense to display video in table view
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: persistencyManager.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(showDownloadProgress), name: Notification.Name(progressUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showDownloadEnd), name: Notification.Name(downloadCompletedNotification), object: nil)
        
        LibraryAPI.shared.clearDB()  // for test purposes only
        
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
        
        do {
            try self.fetchedResultsControllerElement.performFetch()
        } catch {
            print(error)
        }
        
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        fetchRemoteData()
    }
    
    
    fileprivate func fetchRemoteData() {
        
        // do expensive operations in the background thread in order to not block the GUI meanwhile
        DispatchQueue.global(qos: .background).async {
            
            LibraryAPI.shared.updateCoreDataWithJSON()
            LibraryAPI.shared.downloadAssets(types: [.png, .srt])
            
            //self.updateGUI()
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        
        self.fetchRemoteData()
        self.refreshControl.endRefreshing()
        
    }
    
    @IBAction func downloaddAllButtonTouched(_ sender: Any) {
        
        DispatchQueue.global(qos: .background).async {
            
            LibraryAPI.shared.downloadAssets(types: [.mp4])
            print("**************** multiple videos fetched ****************")
            //self.updateGUI()
        }
    }
    
    // MARK: VideoCellDelegate
    func downloadButtonTouched(indexPath: IndexPath) {
        
        // TODO: avoid multiple downloads of the same video
        DispatchQueue.global(qos: .background).async {
            
            LibraryAPI.shared.downloadMP4(index: indexPath.row)
            print("**************** single video fetched ****************")
            //self.updateGUI()
        }
    }
    
    // MARK: DownloadCompletedNotification
    @objc func showDownloadEnd(notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let filename  = userInfo[userInfoFilename] as? String else {
                print("No userInfo found in notification")
                return
        }
        
        DispatchQueue.main.async {
            
            guard let index = Element.getIndex(of: filename) else { return }
            if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? TableViewCell {
                
                cell.hideAllControls()
            }
        }
    }
    
    // MARK: ProgressUpdateNotification
    @objc func showDownloadProgress(notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let progress  = userInfo[userInfoProgress] as? Float,
            let filename  = userInfo[userInfoFilename] as? String else {
                print("No userInfo found in notification")
                return
        }
        
        DispatchQueue.main.async {
            
            guard let index = Element.getIndex(of: filename) else { return }
            if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? TableViewCell {
                cell.showProgress(progress: progress)
            }
        }
    }
    
    @objc func managedObjectContextDidSave(notification: Notification) {
        
        DispatchQueue.main.async {
            print("************* did save ***************")
        }
    }
    
    
    fileprivate func updateGUI() {
        do {
            try self.fetchedResultsControllerElement.performFetch()
            DispatchQueue.main.async {
                // GUI staff only in the main thread!
                self.tableView.reloadData()
            }
        } catch {
            print(error)
        }
    }
    
}

extension ViewController: NSFetchedResultsControllerDelegate {
    
    static var rows = 0
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.tableView.beginUpdates()
        }
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        DispatchQueue.main.async {
            //self.tableView.reloadData()
            self.tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.tableView.endUpdates()
        }
    }
}

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = fetchedResultsControllerElement.sections {
            return sections.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let objects = fetchedResultsControllerElement.fetchedObjects {
            return objects.count
        }
        return 0
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! TableViewCell
        
        let element = fetchedResultsControllerElement.object(at: indexPath)
        guard let assetPNG: Asset = element.assets!.first(where: { ($0 as! Asset).type == AssetType.png.rawValue }) as? Asset, let relativeFilePath = assetPNG.relativeFilePath else {
            return cell
        }
        
        let fileURL = fileHandler.getAbsolutePathURL(from: relativeFilePath)
        
        if let imageData = NSData(contentsOf: fileURL) {
            let image = assetPNG.isCorrupt ? UIImage(named: "placeholderCorrupt") : UIImage(data: imageData as Data)
            cell.imageView!.image = image
        } else {
            cell.imageView!.image = UIImage(named: "placeholderNoData")
        }
        
        cell.videoLabel.text = element.fileName
        
        // display if video is already downloaded or not
        guard let assets = element.assets else {
            return cell
        }
        let mp4 = assets.first { ($0 as! Asset).type == AssetType.mp4.rawValue } as? Asset
        if mp4 != nil && mp4?.relativeFilePath != nil {
            cell.hideAllControls()
            cell.imageView?.alpha = 1.0
            
            if mp4?.isCorrupt == true {
                cell.imageView!.image = UIImage(named: "placeholderCorrupt")
            }
        } else {
            cell.imageView?.alpha = 0.8
        }
 
        // for dwonloading single videos
        cell.delegate = self
        
        return cell
    }
    
    // reset images from reusable cell after scroll -> otherwise we get glitches
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as! TableViewCell).imageView!.image = nil
    }
}

//
//  ViewController.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 01.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import UIKit
import CoreData
import SnapKit

let cellReuseIdentifier = "VideoCell"

class ViewController: UIViewController, VideoCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private let fileHandler = FileHandler()
    private let refreshControl = UIRefreshControl()
    
    private var libraryAPI: LibraryAPI?
    
    let clientContext: ClientContext = {
        
        let persistentContainer = NSPersistentContainer(name: "S3CloudClient", managedObjectModel: ClientContext.clientModel)
        persistentContainer.loadPersistentStores { description, error in
            
            print("description", description)
            print("error", error?.localizedDescription ?? "no error")
        }
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        return ClientContext(persistentContainer: persistentContainer)
    }()
    
    fileprivate lazy var fetchedResultsControllerElement: NSFetchedResultsController<Element> = {
        
        let fetchRequest = NSFetchRequest<Element> (entityName: "Element")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "previewImagePresent == true") // otherwise it doesn't make sense to display elements in table view
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: clientContext.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(showDownloadProgress), name: Notification.Name(progressUpdateNotification), object: nil)
        
        libraryAPI = LibraryAPI.init(with: clientContext)
        libraryAPI?.clearLocalFilesAndSettings() // for test purposes only
        
        self.tableView.register(VideoCell.self)
        self.tableView.tableFooterView = UIView(frame: .zero)
        self.tableView.rowHeight = self.view.frame.size.width / 5.0 // dynamic height - important for small devices such as iPhone SE
        //self.tableView.estimatedRowHeight = 90.0
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
            
            self.libraryAPI?.updateCoreDataWithJSON()
            self.libraryAPI?.downloadAssets(types: [.png, .srt])
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        
        self.fetchRemoteData()
        self.refreshControl.endRefreshing()
        
    }
    
    @IBAction func clearAllButtonTouched(_ sender: Any) {
        
        libraryAPI?.clearLocalFilesAndSettings()
        print("**************** all data cleared ****************")
        
    }
    
    @IBAction func downloaddAllButtonTouched(_ sender: Any) {
        
        DispatchQueue.global(qos: .background).async {
            
            self.libraryAPI?.downloadAssets(types: [.mp4])
            print("**************** multiple videos requested ****************")
        }
    }
    
    // MARK: VideoCellDelegate
    func downloadButtonTouched(indexPath: IndexPath) {
        
        // TODO: avoid multiple downloads of the same video
        DispatchQueue.global(qos: .background).async {
            
            self.libraryAPI?.downloadMP4(index: indexPath.row)
            print("**************** single video requested ****************")
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
            
            guard let index = Element.getIndex(of: filename, context: self.clientContext.persistentContainer.viewContext) else { return }
            if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? VideoCell {
                cell.showProgress(progress: progress)
            }
        }
    }
    
}

// used for dynamically building the tableview:
// as soon as a PNG is downloaded or updated, add a new row to the tableview
extension ViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.tableView.beginUpdates()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        DispatchQueue.main.async {
            
            switch type {
            case .insert:
                self.tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                self.tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                self.tableView.reloadRows(at: [indexPath!], with: .fade)
            case .move:
                self.tableView.moveRow(at: indexPath!, to: newIndexPath!)
            }
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1.0)
        let label = UILabel()
        label.text = "Pull to refresh ..."
        label.textColor = .lightGray
        label.textAlignment = .center
        view.addSubview(label)
        
        // center label horizontally and vertically in section header
        label.snp.makeConstraints { (make) in
            make.width.equalToSuperview().multipliedBy(0.6)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as VideoCell
        
        let element = fetchedResultsControllerElement.object(at: indexPath)
        let viewModel = VideoViewModel(element: element)
        
        cell.setUpWith(viewModel)
  
        // for downloading single videos
        cell.delegate = self
        
        return cell
    }
    
    // reset images from reusable cell after scroll -> otherwise we get glitches
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as! VideoCell).imageView!.image = nil
    }
}

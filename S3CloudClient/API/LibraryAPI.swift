//
//  LibraryAPI.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 01.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import UIKit

/**
 * Facade Pattern:
 *
 * Only LibraryAPI holds instances of
 *  - PersistencyManager,
 *  - FileHandler,
 *  - CloudHandler.
 *
 * Besides, LibraryAPI encapsulates the calls of various Operations.
 *
 * LibraryAPI exposes a simple API to access all those services.
 *
 */
final class LibraryAPI: NSObject {
    

    private var newJSONTimestamp: Bool = false
    
    static let shared = LibraryAPI()
    
    // Helper classes
    private let persistencyManager = PersistencyManager.shared // Singelton due to one unique ManagedObjectContext
    private let fileHandler = FileHandler()
    private let cloudHandler = CloudHandler()
    
    
    // Operations
    private let queue: OperationQueue = OperationQueue()

    
    // Mark: for testing only
    func clearLocalFilesAndSettings() {
        fileHandler.removeAllFiles()
        persistencyManager.clearSQLite()
        UserDefaults.standard.set(nil, forKey: "jsonModificationDate")
    }
    
    // Mark: download JSON data from Cloud
    func updateCoreDataWithJSON()  {
        
        // avoid multiple calls by "pull to refresh"
        if self.queue.operationCount == 0 {
            let processJSONOperation = ProcessJSONOperation(context: persistencyManager.managedObjectContext)
            self.queue.addOperations([processJSONOperation], waitUntilFinished: true)
            self.newJSONTimestamp = processJSONOperation.newJSONTimestamp
            guard let error = processJSONOperation.error else { return }
            displayAlert(message: error.legibleDescription)
        }
    }
    
    // Mark: download assets from Cloud and generate fingerprints
    func downloadAssets(types: [AssetType]) {
        
        if !self.newJSONTimestamp && Element.downloadOfPNGsCompleted() { return }
        
        // avoid multiple calls by "pull to refresh"
        if self.queue.operationCount == 0 {
            let downloadAssetsOperation = DownloadAssetsOperation(types: types, context: self.persistencyManager.managedObjectContext)
            self.queue.addOperations([downloadAssetsOperation], waitUntilFinished: true)
            guard let error = downloadAssetsOperation.error else { return }
            displayAlert(message: error.legibleDescription)
        }
    }
    
    func downloadMP4(index: Int) {
        
        if self.queue.operationCount == 0 {
            let id = index + 1 // video ids start at 1
            let downloadAssetsOperation = DownloadAssetsOperation(id: id, context: persistencyManager.managedObjectContext)
            queue.addOperations([downloadAssetsOperation], waitUntilFinished: true)
            guard let error = downloadAssetsOperation.error else { return }
            displayAlert(message: error.legibleDescription)
        }
    }

}

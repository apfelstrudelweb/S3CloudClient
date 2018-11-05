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
    

    private var timestampHasChanged: Bool = true
    
    static let shared = LibraryAPI()
    
    // Helper classes
    private let persistencyManager = PersistencyManager.shared // Singelton due to one unique ManagedObjectContext
    private let fileHandler = FileHandler()
    private let cloudHandler = CloudHandler()
    
    
    // Operations
    private let queue: OperationQueue = OperationQueue()

    
    // Mark: for testing only
    func clearDB() {
        persistencyManager.clearDB()
        UserDefaults.standard.set(nil, forKey: "jsonModificationDate")
    }
    
    // Mark: download JSON data from Cloud
    func updateCoreDataWithJSON()  {

            let processJSONOperation = ProcessJSONOperation(context: persistencyManager.managedObjectContext)
            self.queue.addOperations([processJSONOperation], waitUntilFinished: true)
            self.timestampHasChanged = processJSONOperation.timestampHasChanged
            guard let error = processJSONOperation.error else { return }
            displayAlert(message: error.legibleDescription)
        
    }
    
    // Mark: download assets from Cloud and generate fingerprints
    func downloadAssets(types: [AssetType]) {
        
        if types.first != .mp4 && !self.timestampHasChanged { return }

            // mp4 must always be downloadable or renewable
            let downloadAssetsOperation = DownloadAssetsOperation(types: types, context: self.persistencyManager.managedObjectContext)
            self.queue.addOperations([downloadAssetsOperation], waitUntilFinished: true)
            guard let error = downloadAssetsOperation.error else { return }
            displayAlert(message: error.legibleDescription)
    }
    
    func downloadMP4(index: Int) {
        
        let id = index + 1 // video ids start at 1
        let downloadAssetsOperation = DownloadAssetsOperation(id: id, context: persistencyManager.managedObjectContext)
        queue.addOperations([downloadAssetsOperation], waitUntilFinished: true)
        guard let error = downloadAssetsOperation.error else { return }
        displayAlert(message: error.legibleDescription)
    }

}

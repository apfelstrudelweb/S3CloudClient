//
//  LibraryAPI.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 01.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import UIKit
import CoreData

/**
 * Facade Pattern:
 *
 * Only LibraryAPI holds instances of
 *  - FileHandler,
 *  - CloudHandler.
 *
 * Besides, LibraryAPI encapsulates the calls of various Operations.
 *
 * LibraryAPI exposes a simple API to access all those services.
 *
 */
final class LibraryAPI: NSObject {
    
    private var clientContext: ClientContext
    private var moc: NSManagedObjectContext
    
    
    private var newJSONTimestamp: Bool = false
    
    // Helper classes
    private let fileHandler = FileHandler()
    private let cloudHandler = CloudHandler()
    
    public init(with context: ClientContext) {
        self.clientContext = context
        self.moc = context.persistentContainer.viewContext
    }
    
 
    // Mark: for testing only
    func clearLocalFilesAndSettings() {
        fileHandler.removeAllFiles()
        clientContext.deleteAllElements()
        //Element.deleteAll(context: moc)
        UserDefaults.standard.set(nil, forKey: "jsonModificationDate")
    }
    
    // Mark: download JSON data from Cloud
    func updateCoreDataWithJSON()  {
        
        let processJSONOperation = ProcessJSONOperation(context: moc)
        self.clientContext.persistenceQueue.addOperations([processJSONOperation], waitUntilFinished: true)
        self.newJSONTimestamp = processJSONOperation.newJSONTimestamp
        guard let error = processJSONOperation.error else { return }
        displayAlert(message: error.legibleDescription)
    }
    
    // Mark: download assets from Cloud and generate fingerprints
    func downloadAssets(types: [AssetType]) {
        
        if !self.newJSONTimestamp && Element.downloadOfPNGsCompleted(context: moc) { return }

        let downloadAssetsOperation = DownloadAssetsOperation(types: types, context: clientContext.persistentContainer.viewContext)
        self.clientContext.persistenceQueue.addOperations([downloadAssetsOperation], waitUntilFinished: true)
        guard let error = downloadAssetsOperation.error else { return }
        displayAlert(message: error.legibleDescription)
    }
    
    func downloadMP4(index: Int) {
 
        let id = index + 1 // video ids start at 1
        let downloadAssetsOperation = DownloadAssetsOperation(id: id, context: moc)
        self.clientContext.persistenceQueue.addOperations([downloadAssetsOperation], waitUntilFinished: true)
        guard let error = downloadAssetsOperation.error else { return }
        displayAlert(message: error.legibleDescription)

    }

}

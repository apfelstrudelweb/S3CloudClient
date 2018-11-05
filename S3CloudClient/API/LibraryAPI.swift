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
    private let persistencyManager = PersistencyManager()
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
    func updateCoreDataWithJSON() throws {
        
        let processJSONOperation = ProcessJSONOperation(context: persistencyManager.managedObjectContext)
        queue.addOperations([processJSONOperation], waitUntilFinished: true)
        self.timestampHasChanged = processJSONOperation.timestampHasChanged
        
        guard let error = processJSONOperation.error else { return }
        throw error
    }
    
    // Mark: download assets from Cloud and generate fingerprints
    func downloadAssets(types: [AssetType]) throws {
        
        // mp4 must always be dwonloadable or renewable
        if types.first != .mp4 && !self.timestampHasChanged { return }

        let downloadAssetsOperation = DownloadAssetsOperation(types: types, context: persistencyManager.managedObjectContext)
        queue.addOperations([downloadAssetsOperation], waitUntilFinished: true)
        guard let error = downloadAssetsOperation.error else { return }
        throw error
    }

}

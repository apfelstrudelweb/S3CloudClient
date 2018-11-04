//
//  ProcessFingerprintsOperation.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 04.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import UIKit
import CoreData

class ProcessFingerprintsOperation: BasicOperation {

    private var context: NSManagedObjectContext
    private var types: [AssetType]
    private let fileHandler = FileHandler()
    
    init(types: [AssetType], context: NSManagedObjectContext) {
        self.context = context
        self.types = types
    }
    
    override func main() {
        
        // 1. get all local assets from CoreData
        guard let assets = Asset.getAllAssets(of: types, inContext: self.context) else {
            self.error = CoreDataError.noResult(reason: "no assets could be found from CoreData before calculating fingerprints of them")
            self.finish()
            return
        }

        for asset in assets {
            
            // get s.th. like "subtitle/Barren.srt"
            guard let relativePath = asset.relativeFilePath, let relativeURL = URL(string: relativePath) else { continue }
            
            // get s.th. like "file:... CoreSimulator/Devices/9BB6BF.../.../Documents/subtitle/Barren.srt"
            let fileURL = fileHandler.getAbsolutePathURL(from: relativePath)
            
            do {
                // 2. calculate fingerprint of each file
                guard let sha256 = try fileHandler.getSha256(filePath: fileURL) else { continue }
                // 3. write local fingerprint to CoreData
                Asset.writeLocalFingerprint(fingerprint: sha256, relativeFilePath: relativeURL, inContext: self.context)

            } catch {
                // TODO: we need to concatenate the possible errors
                self.error = error
            }
            

        }
        
        finish()
        
    }
}

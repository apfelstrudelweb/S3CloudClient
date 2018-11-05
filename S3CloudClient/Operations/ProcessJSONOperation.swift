//
//  ProcessJSONOperation.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 02.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Foundation
import AWSS3
import AWSCore

/**
 * This Operation performs the following tasks:
 *
 *  - download JSON file from Cloud as data - will not be stored in the local file system
 *  - write JSON entities into CoreData
 *
 * The JSON has the following structure:
 * {
 *   "sha256_mp4" : "aade3e747edc189a05fc29da0104dad90e1e1c6e229f80ef6deeae009d5877c3",
 *   "id" : 1,
 *   "alias" : "pullups",
 *   "fileName" : "Pullups",
 *   "sha256_srt" : "b3bdb74c4474e97f7a5b89d93aee116141bb3cc01feed425f9ba7880bbf32104",
 *   "sha256_png" : "5e3a17e29258f7ec12a70929f0ad5886ff3b71cc1a6f8202c7e394409d96906b"
 * }
 *
 * The CoreData entity "Element" is populated with:
 *  - alias: String     (from JSON)
 *  - fileName: String  (from JSON)
 *
 * "Element" has a 1..n relationship with entity "Asset":
 *  for each asset type   (video, image and subtitle) "Element" has an Asset:
 *  - type: Int           (calculated from the file extension)
 *  - sha256: String      (mapped from JSON in conjunction with the asset type - see above)
 *  - localeFilePath: URI (calculated and populated later in the DownloadAssetsOperation - assets need to be in the Sandbox)
 *
 */
final class ProcessJSONOperation: BasicOperation {
    
    //let privateManagedObjectContext: NSManagedObjectContext
    
    public var timestampHasChanged: Bool
    private var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.timestampHasChanged = true
        
        // Initialize Managed Object Context
//        privateManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
//        // Configure Managed Object Context
//        privateManagedObjectContext.persistentStoreCoordinator = context.persistentStoreCoordinator

        
        super.init()
    }

    override func main() {
        
        let expression = AWSS3TransferUtilityDownloadExpression()
        
        var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
        completionHandler = { (task, URL, data, error) -> Void in
            
            // TODO: compare timestamps
            do {
                guard let data = data else {
                    self.error = S3CloudError.noData(reason: "JSON data could not be fetched")
                    self.finish()
                    return
                }
                if data.count == 0 {
                    self.error = S3CloudError.noData(reason: "JSON data are empty")
                    self.finish()
                    return
                }
                if let statusCode = task.response?.statusCode {
                    if statusCode != HTTP_STATUS_OK {
                        self.error = S3CloudError.wrongStatusCode(reason: "While trying to fetch the JSON we got the following status code \(statusCode)")
                        self.finish()
                        return
                    }
                }
                
                if let response = task.response, let jsonModificationDate = response.allHeaderFields["Last-Modified"] as? String {
                    
                    if let savedJsonModificationDate = UserDefaults.standard.object(forKey: "jsonModificationDate") as? String {
                        if savedJsonModificationDate.compare(jsonModificationDate) == .orderedSame {
                            self.timestampHasChanged = false
                            // don't need to download unchanged JSON file
                            self.finish()
                            return
                        } else {
                            UserDefaults.standard.set(jsonModificationDate, forKey: "jsonModificationDate")
                        }
                    } else {
                        UserDefaults.standard.set(jsonModificationDate, forKey: "jsonModificationDate")
                    }
                }
                
                let json = try Array<ElementDecodable>.decode(data: data)
                _ = json.compactMap {
                    print($0)
                    Element.generateFromJson(element: $0)
                }
                
                self.finish()
                
            } catch {
                self.error = error
                self.finish()
                return
            }
        }
        let transferUtility = AWSS3TransferUtility.default()
        transferUtility.downloadData(
            fromBucket: "visualbacktrainer",
            key: "videos.json",
            expression: expression,
            completionHandler: completionHandler)
    }
}

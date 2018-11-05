//
//  DownloadAssetsOperation.swift
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
 *  - download all assets of given AssetType from the Cloud into the Sandbox
 *  - write the local URLs from the downloaded assets into CoreData
 *
 * If not present, subdirectories (such as "image", "video" and "subtitle") are created.
 * Downloaded assets are overwritten by default.
 *
 * This class relies on the AWS API - for further info, please check out "data transfer with TransferUtility":
 * https://docs.aws.amazon.com/de_de/aws-mobile/latest/developerguide/how-to-transfer-files-with-transfer-utility.html
 *
 */
final class DownloadAssetsOperation: BasicOperation {

    
    private let fileHandler = FileHandler()
    
    private var context: NSManagedObjectContext
    private var types: [AssetType]
    
    
    init(types: [AssetType], context: NSManagedObjectContext) {
        self.context = context
        self.types = types
    }
    
    override func main() {
        
        guard let assets = Asset.getAllAssets(of: types, inContext: self.context) else {
            self.error = CoreDataError.noResult(reason: "no assets could be found from CoreData before downloading them")
            self.finish()
            return
        }
        
        var counter = 0
        
        // we need the subdirectories -> they will be the download targets
        fileHandler.createSubdirectories(types: types)
        
        for asset in assets {
            
            guard let fileName = asset.element?.fileName, let type = AssetType(rawValue: asset.type) else { continue }
            
            // if video, only download the remaining ones (previous download may have been aborted)
            if type == .mp4 && asset.relativeFilePath != nil { continue }
            
            // get s.th. like "file:... CoreSimulator/Devices/9BB6BF.../.../Documents/subtitle/Barren.srt"
            guard let targetDownloadURL = fileHandler.getTargetDownloadURL(filename: fileName, type: type) else {
                self.error = FileError.documentsDirNotExisting(reason: "Target Download URL for asset '\(fileName)' does not exist")
                continue
            }
            
            // always overwrite local files
            fileHandler.removeFile(targetDownloadURL)
            
            let key = fileName.keyForBucket(type: type)
            let transferData = TransferData.init(bucket: "visualbacktrainer", key: key, downloadURL: targetDownloadURL)
            downloadAsset(data: transferData, completion: {
                counter += 1
                // when all files are processed, finish OP
                if counter == assets.count {
                    self.finish()
                }
            })
        }
    }
    
    fileprivate func downloadAsset(data: TransferData, completion: @escaping () -> ()) {
        
        guard let downloadURL = data.downloadURL, let bucket = data.bucket, let key = data.key else { return }
        var count = 0
        
        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.progressBlock = { (task, progress) in DispatchQueue.global(qos: .background).async {
            // show progress bar
            if key.assetType() == .mp4 {
                count += 1
                // for the sake of performance: fire notification only every 10 blocks
                if count % 10 == 0 {
                    // show progress bar in UIView
                    let progress = Float(progress.fractionCompleted)
                    let fileName = key.fileNameFromPath() // transform "video/pullups.mp4" -> "pullups"
                    // in order to achieve loose coupling, work with notifications rather than with delegates
                    NotificationCenter.default.post(name: Notification.Name(progressUpdateNotification), object: nil, userInfo: [userInfoProgress : progress, userInfoFilename : fileName])
                }
                
            }
            }
        }
        
        var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
        completionHandler = { (task, fileURL, data, error) -> Void in
            if error != nil {
                self.error = S3CloudError.failedTransfer(reason: error!.localizedDescription)
            }
            // On successful downloads, "URL" contains the S3 object file.
            guard let fileURL = fileURL else {
                completion()
                return
            }
            // set local path URL in CoreData
            guard let relativeURL = URL(string: task.key) else { return }
            Asset.setLocalPath(localPath: relativeURL, inContext: self.context)
            
            // write fingerprint to CoreData
            do {
                if let sha256 = try self.fileHandler.getSha256(filePath: fileURL) {
                    // 3. write local fingerprint to CoreData
                    Asset.writeLocalFingerprint(fingerprint: sha256, relativeFilePath: relativeURL, inContext: self.context)
                }
            } catch {
                // TODO: we need to concatenate the possible errors
                self.error = error
            }
            
            
            let fileName = task.key.fileNameFromPath() // transform "video/pullups.mp4" -> "pullups"
            NotificationCenter.default.post(name: Notification.Name(downloadCompletedNotification), object: nil, userInfo: [userInfoFilename : fileName])
            completion()
        }
        
        let transferUtility = AWSS3TransferUtility.default()
        transferUtility.download(
            to: downloadURL,
            bucket: bucket,
            key: key, // s.th. like "image/Barren.png"
            expression: expression,
            completionHandler: completionHandler).continueWith {
                (task) -> AnyObject? in if let error = task.error {
                    print("Error: \(error.localizedDescription)")
                    self.error = S3CloudError.failedTransfer(reason: error.localizedDescription)
                }
                
                if let _ = task.result {
                    print("download of \"\(key)\" started")
                }
                return nil;
        }
    }
}

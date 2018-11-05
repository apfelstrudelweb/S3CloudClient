//
//  Asset+CoreDataClass.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 02.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Asset)
public class Asset: NSManagedObject {
    
    convenience init(type: Int16, context: NSManagedObjectContext) {
        self.init(context: context)
        self.type = type
    }
    
    class func getAssetOfTypeMP4(with id: Int, inContext context:NSManagedObjectContext) -> Asset? {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Asset")
        let predicate1 = NSPredicate(format: "element.id == %d", id)
        let predicate2 = NSPredicate(format: "type == %d", AssetType.mp4.rawValue)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1,predicate2])
        fetchRequest.predicate = compound
        
        do {
            if let fetchedAsset = try (context.fetch(fetchRequest) as! [Asset]).first {
                return fetchedAsset
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    class func getAllAssets(of types: [AssetType], inContext context:NSManagedObjectContext) -> [Asset]? {
        
        var predicates = [NSPredicate]()
        
        for type in types {
            predicates.append( NSPredicate(format: "type == %d", type.rawValue) )
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Asset")
        fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)

        do {
            
            if let fetchedAssets = try context.fetch(fetchRequest) as? [Asset] {
                return fetchedAssets
            }
            throw CoreDataError.noResult(reason: "no assets could be found in CoreData")
            
        } catch {
            print(error)
        }
        return nil
    }
    
    // iOS 8 onwards, absolute url to app's sandbox changes every time at app start
    // Hence we should never save the absolute url of the asset
    class func setLocalPath(localPath: URL,
                            inContext context:NSManagedObjectContext) {
        
        guard let fileName = localPath.lastPathComponent.components(separatedBy: ".").first else { return } // filename without extension
        let type = localPath.pathExtension.assetType()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Asset")
        let predicate1 = NSPredicate(format: "element.fileName == %@", fileName)
        let predicate2 = NSPredicate(format: "type == %d", type.rawValue)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1,predicate2])
        fetchRequest.predicate = compound

        do {
            if let fetchedAsset = try (context.fetch(fetchRequest) as! [Asset]).first {
                fetchedAsset.relativeFilePath = localPath.absoluteString
                try context.save()
            }

        } catch {
            print(error)
        }
    }
    
    class func writeLocalFingerprint(fingerprint: String, relativeFilePath: URL,
                              inContext context:NSManagedObjectContext) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Asset")
        fetchRequest.predicate = NSPredicate(format: "relativeFilePath == %@", relativeFilePath as CVarArg)
        
        do {
            if let fetchedAsset = try (context.fetch(fetchRequest) as! [Asset]).first {
                fetchedAsset.actual_sha256 = fingerprint
                
                if fingerprint != fetchedAsset.desired_sha256 {
                    fetchedAsset.isCorrupt = true
                } else {
                    // reset if was corrupt before
                    fetchedAsset.isCorrupt = false
                }
                
                try context.save()
            }
            
        } catch {
            print(error)
        }
        
    }
}

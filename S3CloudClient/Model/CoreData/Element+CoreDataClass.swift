//
//  Element+CoreDataClass.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 02.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Element)
public class Element: NSManagedObject {
    
    class func getIndex(of fileName: String, context: NSManagedObjectContext) -> Int? {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Element")
        fetchRequest.predicate = NSPredicate(format: "fileName == %@", fileName)
        
        do {
            
            if let fetchedElement = try context.fetch(fetchRequest).first as? Element {
                return Int(fetchedElement.id) - 1 // index must start from 0
            }
            throw CoreDataError.noResult(reason: "no assets could be found in CoreData")
            
        } catch {
            print(error)
        }
        return nil
    }
    
    class func getAllElements(context: NSManagedObjectContext) -> [String]? {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Element")
        var elements = [String]()
        
        do {
            
            if let fetchedElements = try context.fetch(fetchRequest) as? [Element] {
                
                for element in fetchedElements {
                    
                    guard let filename = element.fileName else { continue }
                    elements.append(filename)
                }
            }
            
        } catch {
            print(error)
        }
        
        return elements
    }
    
    class func downloadOfPNGsCompleted(context: NSManagedObjectContext) -> Bool {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Element")
        //fetchRequest.predicate = NSPredicate(format: "previewImagePresent == true")
        
        do {
            
            if let fetchedElements = try context.fetch(fetchRequest) as? [Element] {
                
                for element in fetchedElements {
                    if element.previewImagePresent == false {
                        return false
                    }
                }
                return true
            }
        } catch {
            print(error)
        }
        return false
    }
    
    class func setDownloadedFlag(fileName: String, type: AssetType, context: NSManagedObjectContext) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Element")
        fetchRequest.predicate = NSPredicate(format: "fileName == %@", fileName)
        
        do {
            
            if let fetchedElement = try context.fetch(fetchRequest).first as? Element {
                
                if type == .png {
                    if fetchedElement.previewImagePresent == false {
                        fetchedElement.previewImagePresent = true
                    }
                } else if type == .mp4 {
                    if fetchedElement.videoPresent == false {
                        fetchedElement.videoPresent = true
                    }
                }
                try context.save()
            }
            
        } catch {
            print(error)
        }
    }
    
    
    class func generateFromJson(element: ElementDecodable, context: NSManagedObjectContext) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Element")
        fetchRequest.predicate = NSPredicate(format: "fileName == %@", element.fileName)
        
        var elementCD: Element?
        var assetsCD: NSSet?
        
        do {
            
            if let fetchedElement = try (context.fetch(fetchRequest) as! [Element]).first {
                elementCD = fetchedElement
                assetsCD = elementCD?.assets
            } else {
                elementCD = Element(context: context)
                assetsCD = [Asset.init(type: AssetType.mp4.rawValue, context: context),
                            Asset.init(type: AssetType.png.rawValue, context: context),
                            Asset.init(type: AssetType.srt.rawValue, context: context)]
            }
            
            let assetMP4 = assetsCD?.first { ($0 as! Asset).type == AssetType.mp4.rawValue } as? Asset
            let assetPNG = assetsCD?.first { ($0 as! Asset).type == AssetType.png.rawValue } as? Asset
            let assetSRT = assetsCD?.first { ($0 as! Asset).type == AssetType.srt.rawValue } as? Asset
  
            assetMP4?.desired_sha256 = element.sha256_mp4
            assetPNG?.desired_sha256 = element.sha256_png
            assetSRT?.desired_sha256 = element.sha256_srt
            
            // localFilePath will be set later
            
            // can be overwritten later when parsing the local filesystem
            assetMP4?.isCorrupt = false
            assetPNG?.isCorrupt = false
            assetSRT?.isCorrupt = false
     
            elementCD?.id = Int64(element.id)
            elementCD?.fileName = element.fileName
            elementCD?.alias = element.alias
            elementCD?.assets = assetsCD
            elementCD?.videoPresent = false
            elementCD?.previewImagePresent = false

            try context.save()
            
        } catch {
            print(error)
        }
    }
    
    class func deleteAll(context: NSManagedObjectContext) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Element")
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                guard let objectData = object as? NSManagedObject else { continue }
                context.delete(objectData)
            }
            try context.save()
        } catch let error {
            print("Detele all data error :", error)
        }
    }

}

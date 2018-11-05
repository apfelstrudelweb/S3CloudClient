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
    
    class func getIndex(of fileName: String, inContext context:NSManagedObjectContext) -> Int? {
        
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
    
    class func getAllElements(inContext context:NSManagedObjectContext) -> [String]? {
        
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
    
    
    class func generateFromJson(element: ElementDecodable,
                                inContext context:NSManagedObjectContext) {
        
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
            
            try context.save()
        } catch {
            print(error)
        }
    }

}

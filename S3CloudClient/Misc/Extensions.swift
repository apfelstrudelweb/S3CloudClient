//
//  Extensions.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 02.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Foundation
import CoreData

public extension URL {
    
    func isPNG() -> Bool {
        return self.absoluteString.contains(".png")
    }
    func isMP4() -> Bool {
        return self.absoluteString.contains(".mp4")
    }
    func isSRT() -> Bool {
        return self.absoluteString.contains(".srt")
    }
}

public extension String {
    
    internal func keyForBucket(type: AssetType) -> String {
        return type.subdirAsString().appending("/").appending(self).appending(".").appending(type.fileExtensionAsString())
    }
    
    internal func assetType() -> AssetType {
        if self.contains("mp4") { return .mp4 }
        else if self.contains("png") { return .png }
        else if self.contains("srt") { return .srt }
        else { return .unknown }
    }
    
    func fileNameFromPath() -> String {
        let fileNameWithExtension = self.components(separatedBy: "/").last ?? "unknown."
        return fileNameWithExtension.components(separatedBy: ".").first ?? ""
    }
}

extension AssetType {
    
    func fileExtensionAsString() -> String {
        switch self {
        case .mp4: return "mp4"
        case .png: return "png"
        case .srt: return "srt"
        case .unknown: return "???"
        }
    }
    
    func subdirAsString() -> String {
        switch self {
        case .mp4: return "video"
        case .png: return "image"
        case .srt: return "subtitle"
        case .unknown: return "???"
        }
    }
}


// see https://github.com/drewmccormack/ensembles/issues/275
// Remedy against "CoreData warning: Multiple NSEntityDescriptions claim the NSManagedObject subclass"
public extension NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: context)!
        self.init(entity: entity, insertInto: context)
    }
}

public extension DispatchQueue {
    
    func async(persistentContainer: NSPersistentContainer, perform: @escaping (NSManagedObjectContext)->Void) {
        
        self.async { [weak persistentContainer] in
            
            persistentContainer?.newBackgroundContext().performIn(perform)
        }
    }
}

public extension OperationQueue {
    
    func addOperation(persistentContainer: NSPersistentContainer, perform: @escaping (NSManagedObjectContext)->Void) {
        
        self.addOperation { [weak persistentContainer] in
            
            persistentContainer?.newBackgroundContext().performAndWaitIn(perform)
        }
    }
}

public extension NSManagedObjectContext {
    
    func performAndWaitIn(_ block:@escaping (NSManagedObjectContext) -> Void) {
        
        self.performAndWait {
            
            block(self)
        }
    }
    
    func performIn(_ block:@escaping (NSManagedObjectContext) -> Void) {
        
        self.perform {
            
            block(self)
        }
    }
    
    func performAndWaitResult<T>(_ block:@escaping (NSManagedObjectContext) -> T?) -> T? {
        
        var result:T?
        self.performAndWait {
            
            result = block(self)
        }
        return result
    }
}

public extension Bundle {
    
    
    func subspecURL(subspecName:String) -> URL {
        return self.bundleURL.appendingPathComponent(subspecName.appending(".bundle"))
    }
    
    
    func dataModelURL(modelName:String) -> URL {
        return self.url(forResource: modelName, withExtension: "momd")!
    }
}

extension ClientContext {
    
    func deleteAllElements() {
        
        self.persistenceQueue.addOperation(persistentContainer: self.persistentContainer) { context in
            
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
}

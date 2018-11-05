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

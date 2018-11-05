//
//  Element+CoreDataProperties.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 05.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//
//

import Foundation
import CoreData


extension Element {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Element> {
        return NSFetchRequest<Element>(entityName: "Element")
    }

    @NSManaged public var alias: String?
    @NSManaged public var fileName: String?
    @NSManaged public var id: Int64
    @NSManaged public var previewImagePresent: Bool
    @NSManaged public var assets: NSSet?

}

// MARK: Generated accessors for assets
extension Element {

    @objc(addAssetsObject:)
    @NSManaged public func addToAssets(_ value: Asset)

    @objc(removeAssetsObject:)
    @NSManaged public func removeFromAssets(_ value: Asset)

    @objc(addAssets:)
    @NSManaged public func addToAssets(_ values: NSSet)

    @objc(removeAssets:)
    @NSManaged public func removeFromAssets(_ values: NSSet)

}

//
//  Asset+CoreDataProperties.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 04.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//
//

import Foundation
import CoreData


extension Asset {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Asset> {
        return NSFetchRequest<Asset>(entityName: "Asset")
    }

    @NSManaged public var isCorrupt: Bool
    @NSManaged public var relativeFilePath: String?
    @NSManaged public var desired_sha256: String?
    @NSManaged public var type: Int16
    @NSManaged public var actual_sha256: String?
    @NSManaged public var element: Element?

}

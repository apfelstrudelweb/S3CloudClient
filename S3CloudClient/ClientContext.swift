//
//  ClientContext.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 11.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Foundation
import CoreData

class ClientContext: NSObject {
    
    public let persistentContainer: NSPersistentContainer
    public let persistenceQueue: OperationQueue = {
        
        let persistenceQueue = OperationQueue()
        persistenceQueue.name = "clientPersistenceQueue"
        persistenceQueue.maxConcurrentOperationCount = 1
        return persistenceQueue
    }()
    
    public init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    public static let clientResourceBundle = Bundle(for: ClientContext.self)
    public static let clientModel = NSManagedObjectModel(contentsOf: clientResourceBundle.dataModelURL(modelName: "S3CloudClient"))!
}

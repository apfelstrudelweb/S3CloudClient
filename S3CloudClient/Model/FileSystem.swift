//
//  FileSystem.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 02.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Foundation

struct LocaleFileMetadata { 
    
    let name: String
    let date: Date
    let size: Int64
    let url: URL
    let sha256: String
    
    init(fileURL: URL, name: String, date: Date, size: Int64, sha256: String) {
        self.name = name
        self.date = date
        self.size = size
        self.url = fileURL
        self.sha256 = sha256
    }
    
    public var debugDescription: String {
        return name + " " + " Size: \(size)"
    }
    
}

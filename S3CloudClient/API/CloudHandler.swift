//
//  CloudHandler.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 01.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import UIKit
import AWSS3
import AWSCore

class CloudHandler: NSObject {
    
    private let fileHandler = FileHandler()
    let context = PersistencyManager.shared.managedObjectContext
    
    override init() {
        super.init()
        setupS3()
    }
    
    
    private func setupS3() {
        // TODO: don't expose credentials in source code!
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey: "00fc196a4e4da27b99ba", secretKey: "MZ9sqsD2RbPQzoOjhm3tGnQ3j3X7ZHG6j8IuB0fe")
        let url = URL(string: "https://s3-de-central.profitbricks.com")
        let endpoint = AWSEndpoint(url: url)
        let defaultServiceConfiguration = AWSServiceConfiguration(region: AWSRegionType.EUCentral1, endpoint: endpoint, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = defaultServiceConfiguration
    }
}

//
//  VideoViewModel.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 11.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Foundation
import UIKit

struct VideoViewModel {
    
    let title: String
    let previewImage: UIImage?
    let showVideoControls: Bool
    
    init(element: Element) {
        
        self.title = element.fileName!
        self.showVideoControls = !element.videoPresent
        
        guard let assetPNG: Asset = element.assets!.first(where: { ($0 as! Asset).type == AssetType.png.rawValue }) as? Asset, let relativeFilePath = assetPNG.relativeFilePath else {
            self.previewImage = UIImage(named: "placeholderNoData")
            return
        }
        
        let fileURL = FileHandler().getAbsolutePathURL(from: relativeFilePath)
        
        if let imageData = NSData(contentsOf: fileURL) {
            let image = assetPNG.isCorrupt ? UIImage(named: "placeholderCorrupt") : UIImage(data: imageData as Data)
            self.previewImage = image!
        } else {
            self.previewImage = UIImage(named: "placeholderNoData")!
        }
        

    }
}

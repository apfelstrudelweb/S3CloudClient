//
//  TableViewCell.swift
//  SubtitleDemo_Example
//
//  Created by Ulrich Vormbrock on 09.10.18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import CircleProgressView

@objc protocol VideoCellDelegate: class {
    @objc optional func downloadButtonTouched(indexPath: IndexPath)
}

class TableViewCell: UITableViewCell {
    
    weak var delegate:VideoCellDelegate?
    
    @IBOutlet weak var circleProgressView: CircleProgressView!
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var videoLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func downloadButtonTouched(_ sender: Any) {
        
        self.downloadButton.setTitle("", for: .normal)
        delegate?.downloadButtonTouched!(indexPath: getIndexPath())
    }
    
    func getIndexPath() -> IndexPath {
        guard let superView = self.superview as? UITableView, let indexPath = superView.indexPath(for: self) else {
            print("superview is not a UITableView - getIndexPath")
            return IndexPath.init()
        }
        
        return indexPath
    }
    
}


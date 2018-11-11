//
//  TableViewCell.swift
//  SubtitleDemo_Example
//
//  Created by Ulrich Vormbrock on 09.10.18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import CircleProgressView
import SnapKit

@objc protocol VideoCellDelegate: class {
    @objc optional func downloadButtonTouched(indexPath: IndexPath)
}

class VideoCell: UITableViewCell {
    
    weak var delegate:VideoCellDelegate?
    
    @IBOutlet weak var circleProgressView: CircleProgressView!
    @IBOutlet weak var videoLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imageView?.insertSubview(circleProgressView, at: 1)
        
        self.circleProgressView.snp.makeConstraints { (make) -> Void in
            make.centerX.equalToSuperview()//.multipliedBy(0.5)
            //make.centerY.equalToSuperview()
        }
        self.downloadButton.snp.makeConstraints { (make) in
            make.left.equalTo(self.imageView!.snp.right).offset(10)
        }
        

        self.downloadButton.imageView?.tintColor = .lightGray

        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        self.imageView!.isUserInteractionEnabled = true
        self.imageView!.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func setUpWith(_ viewModel: VideoViewModel) {
        
        self.videoLabel.text = viewModel.title
        self.imageView?.image = viewModel.previewImage
        self.showVideoControls(state: viewModel.showVideoControls)
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        
        delegate?.downloadButtonTouched!(indexPath: getIndexPath())
    }
    
    @IBAction func downloadButtonTouched(_ sender: Any) {
        
        delegate?.downloadButtonTouched!(indexPath: getIndexPath())
    }
    
    func getIndexPath() -> IndexPath {
        guard let superView = self.superview as? UITableView, let indexPath = superView.indexPath(for: self) else {
            print("superview is not a UITableView - getIndexPath")
            return IndexPath.init()
        }
        
        return indexPath
    }
    
    func showProgress(progress: Float) {
        circleProgressView.progress = Double(progress)
        downloadButton.setImage(nil, for: .normal)
        
        circleProgressView.alpha = 1.0
        downloadButton.setTitle("", for: .normal)
    }
    
    func showVideoControls(state: Bool) {
        imageView?.alpha = state ? 0.8 : 1.0
        circleProgressView.alpha = state ? 1.0 : 0.0
        downloadButton.isEnabled = state
        let downloadImage = state ? UIImage(named: "downloadSymbol") : UIImage(named: "checkmark")
        downloadButton.setImage(downloadImage, for: .normal)
        circleProgressView.progress = 0.0
    }
    
}


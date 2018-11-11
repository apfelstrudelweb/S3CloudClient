//
//  FileHelper.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 01.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Foundation
import CommonCrypto

class FileHandler: NSObject {
    
    func removeAllFiles() {
        
        if let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let types:[AssetType] = [.png, .srt, .mp4]
            
            for type in types {
                // Create subdir such as "image" or "subtitle" if not present
                do {
                    let subdirURL = documentURL.appendingPathComponent(type.subdirAsString())
                    if FileManager.default.fileExists(atPath: subdirURL.path) {
                        try FileManager.default.removeItem(at: subdirURL)
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func removeFile(_ url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("Couldn't remove \(url)")
            }
        }
    }

    func createSubdirectories(types: [AssetType]) {
        
        if let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            for type in types {
                // Create subdir such as "image" or "subtitle" if not present
                do {
                    let subdirURL = documentURL.appendingPathComponent(type.subdirAsString())
                    if !FileManager.default.fileExists(atPath: subdirURL.path) {
                        do {
                            try FileManager.default.createDirectory(atPath: subdirURL.path, withIntermediateDirectories: true, attributes: nil)
                        } catch {
                            throw FileError.subdirNotCreatable(reason: "subdir \(subdirURL.path) could not be created")
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func getTargetDownloadURL(filename: String, type: AssetType) -> URL? {
        
        if let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let subdirURL = documentURL.appendingPathComponent(type.subdirAsString())
            return subdirURL.appendingPathComponent(filename).appendingPathExtension(type.fileExtensionAsString())
        }
        return nil
    }
    
    func getSha256(filePath: URL) throws -> String? {
        
        do {
            let localData = try Data(contentsOf: filePath)
            
            var sha256: String? {
                
                let hash = localData.withUnsafeBytes { (bytes: UnsafePointer<Data>) -> [UInt8] in
                    var hash: [UInt8] = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
                    CC_SHA256(bytes, CC_LONG(localData.count), &hash)
                    return hash
                }
                return hash.map { String(format: "%02x", $0) }.joined()
            }
            return sha256
            
        } catch {
            throw FileError.fingerpringError(reason: "fingerprint of \(filePath.lastPathComponent) could not be generated")
        }
    }
    
    func getAbsolutePathURL(from relativePath: String) -> URL {
        let directoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directoryURL.appendingPathComponent(relativePath)
    }
    
}

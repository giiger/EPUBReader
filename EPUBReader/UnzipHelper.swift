//
//  UnzipHelper.swift
//  EPUBReader
//
//  Created by Alex Giger on 10/17/25.
//

import Foundation
import ZIPFoundation

class UnzipHelper {
    static func unzipEPUB(epubURL: URL, completion: @escaping (URL?) -> Void) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let epubName = (epubURL.lastPathComponent as NSString).deletingPathExtension
        let unzipDirectory = documentsDirectory.appendingPathComponent(epubName)
        
        do {
            // Remove existing directory if it exists
            if FileManager.default.fileExists(atPath: unzipDirectory.path) {
                try FileManager.default.removeItem(at: unzipDirectory)
            }
            
            // Create fresh directory
            try FileManager.default.createDirectory(at: unzipDirectory,
                                                   withIntermediateDirectories: true,
                                                   attributes: nil)
            
            // Unzip
            try FileManager.default.unzipItem(at: epubURL, to: unzipDirectory)
            
            print("EPUB Unzipped successfully.")
            completion(unzipDirectory)
        }
        catch {
            print("Error unzipping file: \(error)")
            completion(nil)
        }
    }
}

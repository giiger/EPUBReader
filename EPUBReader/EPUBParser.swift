//
//  EPUBParser.swift
//  EPUBReader
//
//  Created by Alex Giger on 10/17/25.
//

import Foundation
import SWXMLHash

class EPUBParser: NSObject, XMLParserDelegate {
    private var manifestItems: [String: String] = [:]
    private var spineItems: [String] = []
    private var unzipDirectory: URL!
    private var contentDirectoryPath: String = ""
    
    init(epubDirectory: URL) {
        super.init()
        self.unzipDirectory = epubDirectory
    }
    
    // Parse the EPUB structure once and cache it
    func parseEpubStructure(completion: @escaping (Bool) -> Void) {
        let containerXMLPath = unzipDirectory.appendingPathComponent("META-INF/container.xml").path
        
        guard let containerXMLData = FileManager.default.contents(atPath: containerXMLPath) else {
            print("Could not read container.xml")
            completion(false)
            return
        }
        
        let xml = XMLHash.parse(containerXMLData)
        guard let rootFilePath = xml["container"]["rootfiles"]["rootfile"].element?.attribute(by: "full-path")?.text else {
            print("Could not find rootfile path")
            completion(false)
            return
        }
        
        // Store the content directory (usually OEBPS or OPS)
        contentDirectoryPath = (rootFilePath as NSString).deletingLastPathComponent
        
        let opfURL = unzipDirectory.appendingPathComponent(rootFilePath)
        parseOPFFile(opfURL, completion: completion)
    }
    
    private func parseOPFFile(_ opfURL: URL, completion: @escaping (Bool) -> Void) {
        guard let opfParser = XMLParser(contentsOf: opfURL) else {
            print("Could not create parser for OPF file")
            completion(false)
            return
        }
        
        opfParser.delegate = self
        let success = opfParser.parse()
        
        if success {
            print("Successfully parsed OPF. Found \(spineItems.count) chapters")
            completion(true)
        } else {
            print("Failed to parse OPF file")
            if let error = opfParser.parserError {
                print("Parser error: \(error)")
            }
            completion(false)
        }
    }
    
    // Get a specific chapter URL by index
    func getChapterURL(at index: Int) -> URL? {
        guard index >= 0 && index < spineItems.count else {
            print("Chapter index \(index) out of range (0-\(spineItems.count - 1))")
            return nil
        }
        
        guard let chapterPath = manifestItems[spineItems[index]] else {
            print("Could not find manifest item for spine item: \(spineItems[index])")
            return nil
        }
        
        // Build the full path
        let fullPath: String
        if contentDirectoryPath.isEmpty {
            fullPath = chapterPath
        } else {
            fullPath = "\(contentDirectoryPath)/\(chapterPath)"
        }
        
        let chapterURL = unzipDirectory.appendingPathComponent(fullPath)
        print("Chapter \(index) URL: \(chapterURL.path)")
        
        return chapterURL
    }
    
    // Get total number of chapters
    func getChapterCount() -> Int {
        return spineItems.count
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "itemref", let idref = attributeDict["idref"] {
            spineItems.append(idref)
        }
        else if elementName == "item", let itemId = attributeDict["id"], let href = attributeDict["href"] {
            manifestItems[itemId] = href
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("XML Parse Error: \(parseError)")
    }
}

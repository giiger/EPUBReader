//
//  Book.swift
//  EPUBReader
//
//  Created by Alex Giger on 10/17/25.
//


//  Book.swift
//  EPUBReader

import Foundation
import SwiftData

@Model
class Book {
    var id: UUID
    var title: String
    var fileName: String
    var filePath: String
    var dateAdded: Date
    var lastOpened: Date?
    var currentChapterIndex: Int
    
    init(title: String, fileName: String, filePath: String) {
        self.id = UUID()
        self.title = title
        self.fileName = fileName
        self.filePath = filePath
        self.dateAdded = Date()
        self.currentChapterIndex = 0
    }
}
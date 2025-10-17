//
//  BookReaderView.swift
//  EPUBReader
//
//  Created by Alex Giger on 10/17/25.
//

import SwiftUI

struct BookReaderView: UIViewControllerRepresentable {
    let chapters: [Chapter]
    let startingChapter: Int
    
    func makeUIViewController(context: Context) -> BookReaderViewController {
        return BookReaderViewController(chapters: chapters, startingAt: startingChapter)
    }
    
    func updateUIViewController(_ uiViewController: BookReaderViewController, context: Context) {
        // Update if needed
    }
}

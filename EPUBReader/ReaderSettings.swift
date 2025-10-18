//
//  ReaderSettings.swift
//  EPUBReader
//
//  Created by Alex Giger on 10/17/25.
//


//  ReaderSettings.swift
//  EPUBReader

import Foundation
internal import Combine

class ReaderSettings: ObservableObject {
    static let shared = ReaderSettings()
    
    @Published var fontSize: CGFloat {
        didSet {
            UserDefaults.standard.set(fontSize, forKey: "readerFontSize")
        }
    }
    
    @Published var fontName: String {
        didSet {
            UserDefaults.standard.set(fontName, forKey: "readerFontName")
        }
    }
    
    private init() {
        self.fontSize = UserDefaults.standard.object(forKey: "readerFontSize") as? CGFloat ?? 18.0
        self.fontName = UserDefaults.standard.string(forKey: "readerFontName") ?? "Georgia"
    }
}

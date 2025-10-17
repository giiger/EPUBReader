//
//  ContentView.swift
//  EPUBReader
//
//  Created by Alex Giger on 10/16/25.
//

import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers

struct ContentView: View {
    @State private var showReader = false
    @State private var chapters: [Chapter] = []
    @State private var isLoading = false
    @State private var showFilePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading EPUB...")
                } else {
                    Button("Import EPUB") {
                        showFilePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("EPUB Reader")
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.init(filenameExtension: "epub")!],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .fullScreenCover(isPresented: $showReader) {
            BookReaderView(chapters: chapters, startingChapter: 0)
                .ignoresSafeArea()
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let epubURL = urls.first else { return }
            
            guard epubURL.startAccessingSecurityScopedResource() else {
                print("Could not access file")
                return
            }
            
            defer { epubURL.stopAccessingSecurityScopedResource() }
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsDirectory.appendingPathComponent(epubURL.lastPathComponent)
            
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: epubURL, to: destinationURL)
                
                isLoading = true
                loadEPUB(from: destinationURL)
                
            } catch {
                print("Error copying file: \(error)")
            }
            
        case .failure(let error):
            print("Error importing file: \(error)")
        }
    }
    
    private func loadEPUB(from epubURL: URL) {
        UnzipHelper.unzipEPUB(epubURL: epubURL) { unzipDirectory in
            guard let unzipDirectory = unzipDirectory else {
                print("Error unzipping EPUB")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            parseAllChapters(from: unzipDirectory)
        }
    }
    
    private func parseAllChapters(from unzipDirectory: URL) {
        let parser = EPUBParser(epubDirectory: unzipDirectory)
        
        // First, parse the EPUB structure once
        parser.parseEpubStructure { success in
            guard success else {
                print("Failed to parse EPUB structure")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            // Now get all chapters
            let chapterCount = parser.getChapterCount()
            print("Total chapters found: \(chapterCount)")
            
            var tempChapters: [Chapter] = []
            
            for index in 0..<chapterCount {
                if let chapterURL = parser.getChapterURL(at: index) {
                    let chapter = Chapter(
                        url: chapterURL,
                        index: index,
                        title: "Chapter \(index + 1)"
                    )
                    tempChapters.append(chapter)
                }
            }
            
            DispatchQueue.main.async {
                self.chapters = tempChapters
                self.isLoading = false
                
                if tempChapters.isEmpty {
                    print("No chapters found!")
                } else {
                    self.showReader = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

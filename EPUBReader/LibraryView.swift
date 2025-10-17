//  LibraryView.swift
//  EPUBReader

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.dateAdded, order: .reverse) private var books: [Book]
    @State private var showFilePicker = false
    @State private var isLoading = false
    @State private var selectedBook: Book?
    @State private var chapters: [Chapter] = []
    @State private var showReader = false
    
    var body: some View {
        NavigationView {
            Group {
                if books.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No books yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Import an EPUB to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Import EPUB") {
                            showFilePicker = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(books) { book in
                            BookRowView(book: book)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    openBook(book)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteBook(book)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFilePicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Loading book...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                }
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.init(filenameExtension: "epub")!],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .fullScreenCover(isPresented: $showReader) {
            if let book = selectedBook {
                BookReaderView(chapters: chapters, startingChapter: book.currentChapterIndex)
                    .ignoresSafeArea()
                    .onDisappear {
                        // Save reading progress if needed
                    }
            }
        }
    }
    
    private func openBook(_ book: Book) {
        isLoading = true
        selectedBook = book
        
        let bookURL = URL(fileURLWithPath: book.filePath)
        loadEPUB(from: bookURL, book: book)
    }
    
    private func deleteBook(_ book: Book) {
        // Delete the unzipped directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let epubName = (book.fileName as NSString).deletingPathExtension
        let unzipDirectory = documentsDirectory.appendingPathComponent(epubName)
        
        try? FileManager.default.removeItem(at: unzipDirectory)
        
        // Delete the EPUB file
        let epubURL = URL(fileURLWithPath: book.filePath)
        try? FileManager.default.removeItem(at: epubURL)
        
        // Delete from database
        modelContext.delete(book)
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
                
                // Extract title from EPUB metadata (simplified - you might want to parse the OPF for actual title)
                let title = epubURL.deletingPathExtension().lastPathComponent
                
                // Create book record
                let newBook = Book(
                    title: title,
                    fileName: epubURL.lastPathComponent,
                    filePath: destinationURL.path
                )
                
                modelContext.insert(newBook)
                try modelContext.save()
                
                isLoading = false
                
            } catch {
                print("Error copying file: \(error)")
                isLoading = false
            }
            
        case .failure(let error):
            print("Error importing file: \(error)")
        }
    }
    
    private func loadEPUB(from epubURL: URL, book: Book) {
        UnzipHelper.unzipEPUB(epubURL: epubURL) { unzipDirectory in
            guard let unzipDirectory = unzipDirectory else {
                print("Error unzipping EPUB")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            parseAllChapters(from: unzipDirectory, book: book)
        }
    }
    
    private func parseAllChapters(from unzipDirectory: URL, book: Book) {
        let parser = EPUBParser(epubDirectory: unzipDirectory)
        
        parser.parseEpubStructure { success in
            guard success else {
                print("Failed to parse EPUB structure")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            let chapterCount = parser.getChapterCount()
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
                    book.lastOpened = Date()
                    try? self.modelContext.save()
                    self.showReader = true
                }
            }
        }
    }
}

struct BookRowView: View {
    let book: Book
    
    var body: some View {
        HStack {
            Image(systemName: "book.closed.fill")
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                
                if let lastOpened = book.lastOpened {
                    Text("Last opened: \(lastOpened.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not yet opened")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: Book.self, inMemory: true)
}
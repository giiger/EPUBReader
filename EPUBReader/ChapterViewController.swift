//
//  ChapterViewController.swift
//  EPUBReader
//
//  Created by Alex Giger on 10/17/25.
//

import UIKit
import WebKit

class ChapterViewController: UIViewController, WKNavigationDelegate {
    var chapter: Chapter?
    var pageIndex: Int = 0
    
    private var webView: WKWebView!
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.backgroundColor = .systemBackground
        webView.navigationDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        loadChapterContent()
    }
    
    private func loadChapterContent() {
        guard let chapter = chapter else { return }
        
        activityIndicator.startAnimating()
        
        // Get the EPUB root directory for file access
        var epubRoot = chapter.url.deletingLastPathComponent()
        
        // Navigate up to find the EPUB root (the unzipped folder)
        while epubRoot.pathComponents.count > 1 {
            let contents = try? FileManager.default.contentsOfDirectory(atPath: epubRoot.path)
            if contents?.contains("META-INF") == true {
                break
            }
            epubRoot = epubRoot.deletingLastPathComponent()
        }
        
        print("Chapter URL: \(chapter.url.path)")
        print("EPUB Root: \(epubRoot.path)")
        
        // Load the file with access to the entire EPUB directory
        webView.loadFileURL(chapter.url, allowingReadAccessTo: epubRoot)
        activityIndicator.stopAnimating()
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ Chapter loaded successfully")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ WebView failed: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ Provisional navigation failed: \(error.localizedDescription)")
    }
}

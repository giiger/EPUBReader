//
//  PageViewController.swift
//  EPUBReader
//
//  Created by Alex Giger on 10/17/25.
//

import UIKit

class PageViewController: UIViewController {
    var page: Page?
    var pageIndexInBook: Int = 0
    private let settings = ReaderSettings.shared
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .systemBackground
        textView.textColor = .label  // Add this line
        textView.textContainerInset = UIEdgeInsets(top: 40, left: 30, bottom: 80, right: 30)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let pageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupUI()
        displayPage()
    }
    
    private func setupUI() {
        view.addSubview(textView)
        view.addSubview(pageLabel)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            pageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func displayPage() {
        guard let page = page else { return }
        
        let font = UIFont(name: settings.fontName, size: settings.fontSize) ?? UIFont.systemFont(ofSize: settings.fontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .justified
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label,  // Add text color here too
            .paragraphStyle: paragraphStyle
        ]
        
        textView.attributedText = NSAttributedString(string: page.content, attributes: attributes)
        pageLabel.text = "Page \(page.pageIndex + 1) of \(page.totalPagesInChapter)"
        
        // Debug: Check if we have content
        print("Displaying page with \(page.content.count) characters")
        if page.content.isEmpty {
            print("⚠️ Warning: Page content is empty!")
        }
    }
}

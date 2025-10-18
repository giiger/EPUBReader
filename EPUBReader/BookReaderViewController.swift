//
//  BookReaderViewController.swift
//  EPUBReader
//
//  Created by Alex Giger on 10/17/25.
//

import UIKit

class BookReaderViewController: UIPageViewController {
    var chapters: [Chapter] = []
    var startingChapterIndex: Int = 0
    
    private var allPages: [Page] = []
    private var currentPageIndex = 0
    private let settings = ReaderSettings.shared
    private var isLoadingPages = false
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        button.setImage(UIImage(systemName: "textformat.size", withConfiguration: config), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let chapterLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    init(chapters: [Chapter], startingAt index: Int = 0) {
        self.chapters = chapters
        self.startingChapterIndex = index
        super.init(transitionStyle: .pageCurl, navigationOrientation: .horizontal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupLoadingIndicator()
        
        loadAllPages()
    }
    
    private func setupNavigationBar() {
        view.addSubview(closeButton)
        view.addSubview(settingsButton)
        view.addSubview(chapterLabel)
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            chapterLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            chapterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadAllPages() {
        guard !isLoadingPages else { return }
        isLoadingPages = true
        loadingIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var pages: [Page] = []
            let containerSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            
            for (chapterIndex, chapter) in self.chapters.enumerated() {
                // Update progress on main thread
                DispatchQueue.main.async {
                    self.chapterLabel.text = "Loading chapter \(chapterIndex + 1) of \(self.chapters.count)..."
                }
                
                guard let htmlContent = try? String(contentsOf: chapter.url, encoding: .utf8) else {
                    print("Could not read chapter \(chapterIndex)")
                    continue
                }
                
                let pageTexts = TextPaginator.paginateHTML(
                    html: htmlContent,
                    containerSize: containerSize,
                    fontSize: self.settings.fontSize,
                    fontName: self.settings.fontName
                )
                
                for (pageIndex, pageText) in pageTexts.enumerated() {
                    let page = Page(
                        chapterIndex: chapterIndex,
                        pageIndex: pageIndex,
                        content: pageText,
                        totalPagesInChapter: pageTexts.count
                    )
                    pages.append(page)
                }
            }
            
            DispatchQueue.main.async {
                self.allPages = pages
                self.isLoadingPages = false
                self.loadingIndicator.stopAnimating()
                
                // Find the first page of the starting chapter
                let startPage = pages.first(where: { $0.chapterIndex == self.startingChapterIndex }) ?? pages.first
                if let startPage = startPage,
                   let startIndex = pages.firstIndex(where: { $0.chapterIndex == startPage.chapterIndex && $0.pageIndex == startPage.pageIndex }) {
                    self.currentPageIndex = startIndex
                    if let firstVC = self.viewControllerAtIndex(startIndex) {
                        self.setViewControllers([firstVC], direction: .forward, animated: false)
                        self.updateChapterLabel()
                    }
                }
            }
        }
    }
    
    private func reloadAllPages() {
        // Save current chapter
        let currentChapterIndex = allPages.isEmpty ? startingChapterIndex : allPages[currentPageIndex].chapterIndex
        
        // Clear current pages
        allPages.removeAll()
        
        // Reload with new settings
        startingChapterIndex = currentChapterIndex
        loadAllPages()
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func settingsTapped() {
        let settingsVC = FontSettingsViewController()
        settingsVC.onSettingsChanged = { [weak self] in
            self?.reloadAllPages()
        }
        
        let navController = UINavigationController(rootViewController: settingsVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }
    
    private func updateChapterLabel() {
        guard !allPages.isEmpty, currentPageIndex < allPages.count else { return }
        let currentPage = allPages[currentPageIndex]
        chapterLabel.text = "Chapter \(currentPage.chapterIndex + 1) of \(chapters.count)"
    }
    
    func viewControllerAtIndex(_ index: Int) -> PageViewController? {
        guard index >= 0 && index < allPages.count else { return nil }
        
        let pageVC = PageViewController()
        pageVC.page = allPages[index]
        pageVC.pageIndexInBook = index
        return pageVC
    }
}

// MARK: - UIPageViewControllerDataSource
extension BookReaderViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let pageVC = viewController as? PageViewController else { return nil }
        return viewControllerAtIndex(pageVC.pageIndexInBook - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let pageVC = viewController as? PageViewController else { return nil }
        return viewControllerAtIndex(pageVC.pageIndexInBook + 1)
    }
}

// MARK: - UIPageViewControllerDelegate
extension BookReaderViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let visibleVC = pageViewController.viewControllers?.first as? PageViewController {
            currentPageIndex = visibleVC.pageIndexInBook
            updateChapterLabel()
        }
    }
}

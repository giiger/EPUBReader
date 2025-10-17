//
//  BookReaderViewController.swift
//  EPUBReader
//
//  Created by Alex Giger on 10/17/25.
//

import UIKit

class BookReaderViewController: UIPageViewController {
    var chapters: [Chapter] = []
    private var currentChapterIndex = 0
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
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
    
    init(chapters: [Chapter], startingAt index: Int = 0) {
        self.chapters = chapters
        self.currentChapterIndex = index
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
        
        // Load first chapter
        if let firstVC = viewControllerAtIndex(currentChapterIndex) {
            setViewControllers([firstVC], direction: .forward, animated: false)
            updateChapterLabel()
        }
    }
    
    private func setupNavigationBar() {
        view.addSubview(closeButton)
        view.addSubview(chapterLabel)
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            chapterLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            chapterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    private func updateChapterLabel() {
        chapterLabel.text = "Chapter \(currentChapterIndex + 1) of \(chapters.count)"
    }
    
    func viewControllerAtIndex(_ index: Int) -> ChapterViewController? {
        guard index >= 0 && index < chapters.count else { return nil }
        
        let chapterVC = ChapterViewController()
        chapterVC.chapter = chapters[index]
        chapterVC.pageIndex = index
        return chapterVC
    }
}

// MARK: - UIPageViewControllerDataSource
extension BookReaderViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let chapterVC = viewController as? ChapterViewController else { return nil }
        return viewControllerAtIndex(chapterVC.pageIndex - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let chapterVC = viewController as? ChapterViewController else { return nil }
        return viewControllerAtIndex(chapterVC.pageIndex + 1)
    }
}

// MARK: - UIPageViewControllerDelegate
extension BookReaderViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let visibleVC = pageViewController.viewControllers?.first as? ChapterViewController {
            currentChapterIndex = visibleVC.pageIndex
            updateChapterLabel()
        }
    }
}

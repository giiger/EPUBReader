//
//  FontSettingsViewController.swift
//  EPUBReader
//
//  Created by Alex Giger on 10/17/25.
//


//  FontSettingsViewController.swift
//  EPUBReader

import UIKit

class FontSettingsViewController: UIViewController {
    var onSettingsChanged: (() -> Void)?
    private let settings = ReaderSettings.shared
    
    private let fontSizeLabel: UILabel = {
        let label = UILabel()
        label.text = "Font Size"
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let fontSizeValueLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let fontSizeSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 12
        slider.maximumValue = 32
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private let smallLabel: UILabel = {
        let label = UILabel()
        label.text = "A"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let largeLabel: UILabel = {
        let label = UILabel()
        label.text = "A"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Reading Settings"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        setupUI()
        updateFontSizeDisplay()
        
        fontSizeSlider.value = Float(settings.fontSize)
        fontSizeSlider.addTarget(self, action: #selector(fontSizeChanged), for: .valueChanged)
    }
    
    private func setupUI() {
        view.addSubview(fontSizeLabel)
        view.addSubview(fontSizeValueLabel)
        view.addSubview(smallLabel)
        view.addSubview(fontSizeSlider)
        view.addSubview(largeLabel)
        
        NSLayoutConstraint.activate([
            fontSizeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            fontSizeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            fontSizeValueLabel.centerYAnchor.constraint(equalTo: fontSizeLabel.centerYAnchor),
            fontSizeValueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            smallLabel.topAnchor.constraint(equalTo: fontSizeLabel.bottomAnchor, constant: 30),
            smallLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            fontSizeSlider.centerYAnchor.constraint(equalTo: smallLabel.centerYAnchor),
            fontSizeSlider.leadingAnchor.constraint(equalTo: smallLabel.trailingAnchor, constant: 15),
            fontSizeSlider.trailingAnchor.constraint(equalTo: largeLabel.leadingAnchor, constant: -15),
            
            largeLabel.centerYAnchor.constraint(equalTo: smallLabel.centerYAnchor),
            largeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    @objc private func fontSizeChanged() {
        settings.fontSize = CGFloat(fontSizeSlider.value)
        updateFontSizeDisplay()
        onSettingsChanged?()
    }
    
    private func updateFontSizeDisplay() {
        fontSizeValueLabel.text = "\(Int(settings.fontSize))pt"
    }
    
    @objc private func doneTapped() {
        dismiss(animated: true)
    }
}
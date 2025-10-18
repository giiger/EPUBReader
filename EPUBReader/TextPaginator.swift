//
//  TextPaginator.swift
//  EPUBReader
//
//  Created by Alex Giger on 10/17/25.
//

import UIKit

class TextPaginator {
    static func paginateHTML(
        html: String,
        containerSize: CGSize,
        fontSize: CGFloat,
        fontName: String
    ) -> [String] {
        
        // Strip HTML tags and get plain text
        let plainText = stripHTML(html)
        
        if plainText.isEmpty {
            return []
        }
        
        // Create attributed string with font
        let font = UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .justified
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedText = NSAttributedString(string: plainText, attributes: attributes)
        
        // Calculate usable text area (accounting for margins)
        let textInsets = UIEdgeInsets(top: 40, left: 30, bottom: 80, right: 30)
        let textContainerSize = CGSize(
            width: containerSize.width - textInsets.left - textInsets.right,
            height: containerSize.height - textInsets.top - textInsets.bottom
        )
        
        var pages: [String] = []
        var remainingText = plainText
        var safetyCounter = 0
        let maxPages = 1000 // Safety limit
        
        while !remainingText.isEmpty && safetyCounter < maxPages {
            safetyCounter += 1
            
            // Create new text storage and layout manager for each iteration
            let currentAttributedText = NSAttributedString(string: remainingText, attributes: attributes)
            let textStorage = NSTextStorage(attributedString: currentAttributedText)
            let layoutManager = NSLayoutManager()
            let textContainer = NSTextContainer(size: textContainerSize)
            
            textContainer.lineFragmentPadding = 0
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
            
            // Force layout
            layoutManager.glyphRange(for: textContainer)
            
            // Get the range of text that fits
            let glyphRange = layoutManager.glyphRange(for: textContainer)
            let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            
            // Safety check: if no characters fit, break
            if characterRange.length == 0 {
                print("Warning: No text fits on page. Breaking to avoid infinite loop.")
                if !remainingText.isEmpty {
                    // Add remaining text as one page to avoid losing content
                    pages.append(remainingText)
                }
                break
            }
            
            // Check if we've processed all remaining text
            if characterRange.length >= remainingText.count {
                // This is the last page
                pages.append(remainingText)
                break
            }
            
            // Extract the text for this page
            let pageText = (remainingText as NSString).substring(with: NSRange(location: 0, length: characterRange.length))
            pages.append(pageText)
            
            // Update remaining text
            remainingText = (remainingText as NSString).substring(from: characterRange.length)
        }
        
        if safetyCounter >= maxPages {
            print("Warning: Hit maximum page limit. Possible infinite loop prevented.")
        }
        
        print("Paginated into \(pages.count) pages")
        return pages.isEmpty ? [plainText] : pages
    }
    
    private static func stripHTML(_ html: String) -> String {
        // Remove script and style tags with their content
        var text = html
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        
        // Remove HTML tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Decode HTML entities
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        text = text.replacingOccurrences(of: "&apos;", with: "'")
        
        // More common entities
        let entities = [
            ("&mdash;", "—"),
            ("&ndash;", "–"),
            ("&rsquo;", "'"),
            ("&lsquo;", "'"),
            ("&rdquo;", "\""),
            ("&ldquo;", "\""),
            ("&hellip;", "…"),
            ("&bull;", "•")
        ]
        
        for (entity, replacement) in entities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Clean up extra whitespace but preserve paragraph breaks
        text = text.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\n[ \\t]+", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return text
    }
}

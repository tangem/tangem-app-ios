//
//  AttributedTextView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS, obsoleted: 15, message: "Should be replaced on AttributedString + Text")
struct AttributedTextView: UIViewRepresentable {
    let attributedString: NSAttributedString
    let textAlignment: NSTextAlignment?
    let maxLayoutWidth: CGFloat?

    init(_ attributedString: NSAttributedString, textAlignment: NSTextAlignment? = nil, maxLayoutWidth: CGFloat? = nil) {
        self.attributedString = attributedString
        self.textAlignment = textAlignment
        self.maxLayoutWidth = maxLayoutWidth
    }

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()

        label.lineBreakMode = .byClipping
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true

        if let textAlignment {
            label.textAlignment = textAlignment
        }

        if let maxLayoutWidth {
            label.preferredMaxLayoutWidth = maxLayoutWidth
        }

        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = attributedString
        uiView.sizeToFit()

        if let textAlignment {
            uiView.textAlignment = textAlignment
        }

        if let maxLayoutWidth {
            uiView.preferredMaxLayoutWidth = maxLayoutWidth
        }
    }
}

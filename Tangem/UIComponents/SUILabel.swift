//
//  SUILabel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct SUILabel: View {
    var attributedString: NSAttributedString
    var lineLimit: Int

    init(_ attributedString: NSAttributedString, lineLimit: Int = 0) {
        self.attributedString = attributedString
        self.lineLimit = lineLimit
    }

    var body: some View {
        HorizontalGeometryReader { width in
            UILabelView(
                attributedString: attributedString,
                preferredMaxLayoutWidth: width,
                lineLimit: lineLimit
            )
        }
    }
}

// MARK: - UILabelView

private struct UILabelView: UIViewRepresentable {
    let attributedString: NSAttributedString

    var preferredMaxLayoutWidth: CGFloat = .greatestFiniteMagnitude
    var lineLimit: Int = 0

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel(frame: .zero)

        label.numberOfLines = lineLimit
        label.attributedText = attributedString

        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = attributedString
        uiView.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        uiView.numberOfLines = lineLimit
    }
}

// MARK: - HorizontalGeometryReader

private struct HorizontalGeometryReader<Content: View>: View {
    var content: (CGFloat) -> Content
    @State private var width: CGFloat = 0

    public init(@ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(width)
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: WidthPreferenceKey.self, value: geometry.size.width)
                }
            )
            .onPreferenceChange(WidthPreferenceKey.self) { width in
                self.width = width
            }
    }
}

private struct WidthPreferenceKey: PreferenceKey, Equatable {
    static var defaultValue: CGFloat = 0
    /// An empty reduce implementation takes the first value
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}

//
//  PolymarketPositionStatTile.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct PolymarketPositionStatTile: View {
    private let model: Model

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        if let onHintTap = model.onHintTap {
            SwiftUI.Button(action: onHintTap) { tile }
                .buttonStyle(.plain)
                .accessibilityLabel("\(model.caption), \(model.value)")
        } else {
            tile
        }
    }

    private var tile: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            Text(model.value)
                .style(DesignSystem.Font.headingSmallToken, color: model.tone.textColor)
                .lineLimit(1)
                .minimumScaleFactor(Constants.minimumScaleFactor)

            caption
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.padding)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
        .contentShape(Rectangle())
    }

    private var caption: some View {
        HStack(spacing: Constants.captionSpacing) {
            Text(model.caption)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            if model.onHintTap != nil {
                DesignSystem.Icons.Info.regular16.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: Constants.hintSide))
                    .foregroundStyle(DesignSystem.Color.iconTertiary)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Model

public extension PolymarketPositionStatTile {
    struct Model: Identifiable {
        public let id: String
        public let caption: String
        public let value: String
        public let tone: PolymarketValueTone
        public let onHintTap: (() -> Void)?

        public init(
            id: String,
            caption: String,
            value: String,
            tone: PolymarketValueTone = .neutral,
            onHintTap: (() -> Void)? = nil
        ) {
            self.id = id
            self.caption = caption
            self.value = value
            self.tone = tone
            self.onHintTap = onHintTap
        }
    }
}

// MARK: - Constants

private extension PolymarketPositionStatTile {
    enum Constants {
        static let spacing: CGFloat = 2
        static let captionSpacing: CGFloat = 4
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 24
        static let hintSide: CGFloat = 16
        static let minimumScaleFactor: CGFloat = 0.7
    }
}

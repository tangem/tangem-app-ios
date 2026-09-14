//
//  PolymarketPositionRow.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUI
import TangemUIUtils

public struct PolymarketPositionRow: View {
    private let model: Model
    private let onTap: (() -> Void)?

    public init(model: Model, onTap: (() -> Void)? = nil) {
        self.model = model
        self.onTap = onTap
    }

    public var body: some View {
        card
            .ifLet(model.glowRing) { $0.glowRing($1, size: .card(cornerRadius: Constants.cornerRadius)) }
    }

    private var card: some View {
        row
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var row: some View {
        let row = TangemUI.Row(title: model.question)
            .titleLineLimit(Constants.titleLineLimit)
            .verticalAlignment(.center)
            .end { PolymarketAvatarView(url: model.imageURL) }
            .extraBottom { footer }

        if let onTap {
            row.onTap(onTap)
        } else {
            row
        }
    }

    private var footer: some View {
        HStack(spacing: Constants.spacing) {
            PolymarketOutcomeBubble(title: model.outcomeTitle, style: model.outcomeStyle)

            PriceChangeView(
                state: .loaded(changeType: model.changeType, text: model.changeText),
                showIconForNeutral: false,
                useRedesignColors: true
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.changeType.accessibilitySign + model.changeText)

            Spacer(minLength: Constants.spacing)

            trailing
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var trailing: some View {
        switch model.trailing {
        case .value(let text):
            Text(text)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
        case .settled(let text):
            Badge(label: text, accessibilityLabel: nil)
                .size(.x6)
                .variant(.solid)
        }
    }
}

// MARK: - Model

public extension PolymarketPositionRow {
    struct Model: Identifiable, Hashable {
        public let id: String
        public let question: String
        public let imageURL: URL?
        public let outcomeTitle: String
        public let outcomeStyle: PolymarketOutcomeStyle
        public let changeText: String
        public let changeType: PriceChangeView.ChangeType
        public let trailing: Trailing
        public let glowRing: GlowRingAppearance?

        public init(
            id: String,
            question: String,
            imageURL: URL?,
            outcomeTitle: String,
            outcomeStyle: PolymarketOutcomeStyle,
            changeText: String,
            changeType: PriceChangeView.ChangeType,
            trailing: Trailing,
            glowRing: GlowRingAppearance?
        ) {
            self.id = id
            self.question = question
            self.imageURL = imageURL
            self.outcomeTitle = outcomeTitle
            self.outcomeStyle = outcomeStyle
            self.changeText = changeText
            self.changeType = changeType
            self.trailing = trailing
            self.glowRing = glowRing
        }
    }

    enum Trailing: Hashable {
        case value(String)
        case settled(String)
    }
}

// MARK: - Change direction

private extension PriceChangeView.ChangeType {
    var accessibilitySign: String {
        switch self {
        case .positive: String.plusSign
        case .negative: String.minusSign
        case .neutral: .empty
        }
    }
}

// MARK: - Constants

private extension PolymarketPositionRow {
    enum Constants {
        static let cornerRadius: CGFloat = 24
        static let titleLineLimit = 2
        static let spacing: CGFloat = 4
    }
}

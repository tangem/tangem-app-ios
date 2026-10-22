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
        TangemUI.Row(title: model.question)
            .titleLineLimit(Constants.titleLineLimit)
            .verticalAlignment(.center)
            .end { PolymarketAvatarView(url: model.imageURL) }
            .extraBottom { footer }
            .onTap(action: onTap)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    private var footer: some View {
        HStack(spacing: Constants.spacing) {
            PolymarketOutcomeBubble(title: model.outcomeTitle, style: model.outcomeStyle)

            PriceChangeView(
                state: .loaded(changeType: model.change.type, text: model.change.text),
                showIconForNeutral: false,
                useRedesignColors: true
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.change.type.accessibilitySign + model.change.text)

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
        case .status(let status):
            Badge(label: status.text, accessibilityLabel: nil)
                .size(.x6)
                .variant(status.variant)
                .appearance(status.appearance)
                .slotStart(status.icon)
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
        public let change: Change
        public let trailing: Trailing
        public let glowRing: GlowRingAppearance?

        public init(
            id: String,
            question: String,
            imageURL: URL?,
            outcomeTitle: String,
            outcomeStyle: PolymarketOutcomeStyle,
            change: Change,
            trailing: Trailing,
            glowRing: GlowRingAppearance?
        ) {
            self.id = id
            self.question = question
            self.imageURL = imageURL
            self.outcomeTitle = outcomeTitle
            self.outcomeStyle = outcomeStyle
            self.change = change
            self.trailing = trailing
            self.glowRing = glowRing
        }
    }

    struct Change: Hashable {
        public let text: String
        public let type: PriceChangeView.ChangeType

        public init(text: String, type: PriceChangeView.ChangeType) {
            self.text = text
            self.type = type
        }
    }

    enum Trailing: Hashable {
        case value(String)
        case status(Status)
    }

    struct Status: Hashable {
        public let text: String
        public let variant: BadgeVariant
        public let appearance: BadgeAppearance
        public let icon: ImageType?

        public init(text: String, variant: BadgeVariant, appearance: BadgeAppearance, icon: ImageType?) {
            self.text = text
            self.variant = variant
            self.appearance = appearance
            self.icon = icon
        }
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

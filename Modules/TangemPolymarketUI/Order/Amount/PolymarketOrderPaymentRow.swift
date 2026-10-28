//
//  PolymarketOrderPaymentRow.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

public struct PolymarketOrderPaymentRow: View {
    private let model: Model
    private let style: PolymarketOrderBlockStyle
    private let isAddFundsEnabled: Bool
    private let onAddFunds: () -> Void

    public init(
        model: Model,
        style: PolymarketOrderBlockStyle = .regular,
        isAddFundsEnabled: Bool,
        onAddFunds: @escaping () -> Void
    ) {
        self.model = model
        self.style = style
        self.isAddFundsEnabled = isAddFundsEnabled
        self.onAddFunds = onAddFunds
    }

    public var body: some View {
        HStack(spacing: Constants.spacing) {
            icon

            texts

            Spacer(minLength: Constants.spacing)

            addFundsButton
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, verticalPadding)
    }

    private var verticalPadding: CGFloat {
        switch style {
        case .regular: Constants.regularVerticalPadding
        case .sheet: Constants.sheetVerticalPadding
        }
    }

    private var iconSide: CGFloat {
        switch style {
        case .regular: Constants.regularIconSide
        case .sheet: Constants.sheetIconSide
        }
    }

    private var icon: some View {
        model.icon.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(size: CGSize(bothDimensions: iconSide))
            .accessibilityHidden(true)
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: Constants.textSpacing) {
            Text(model.symbol)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)

            Text(Localization.commonBalance(model.balanceText))
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)
        }
    }

    private var addFundsButton: some View {
        TangemUI.Button(
            label: Localization.commonAddFunds,
            accessibilityLabel: Localization.commonAddFunds,
            action: onAddFunds
        )
        .size(.x8)
        .styleType(.secondary(.default))
        .disabled(!isAddFundsEnabled)
        .overlay {
            if !isAddFundsEnabled {
                Color.clear
                    .contentShape(.rect)
                    .onTapGesture(perform: onAddFunds)
                    .environment(\.isEnabled, true)
            }
        }
    }
}

// MARK: - Model

public extension PolymarketOrderPaymentRow {
    struct Model {
        public let icon: ImageType
        public let symbol: String
        public let balanceText: String

        public init(icon: ImageType, symbol: String, balanceText: String) {
            self.icon = icon
            self.symbol = symbol
            self.balanceText = balanceText
        }
    }
}

// MARK: - Constants

private extension PolymarketOrderPaymentRow {
    enum Constants {
        static let spacing: CGFloat = 12
        static let textSpacing: CGFloat = 2
        static let horizontalPadding: CGFloat = 16
        static let regularVerticalPadding: CGFloat = 12
        static let sheetVerticalPadding: CGFloat = 16
        static let regularIconSide: CGFloat = 36
        static let sheetIconSide: CGFloat = 40
    }
}

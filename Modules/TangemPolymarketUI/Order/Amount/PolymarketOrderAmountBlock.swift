//
//  PolymarketOrderAmountBlock.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

public struct PolymarketOrderAmountBlock<Field: View, Footer: View, Bottom: View>: View {
    private let title: String
    private let style: PolymarketOrderBlockStyle
    private let payment: PolymarketOrderPaymentRow.Model?
    private let isAddFundsEnabled: Bool
    private let onAddFunds: () -> Void
    private let field: Field
    private let footer: Footer
    private let bottom: Bottom

    public init(
        title: String = Localization.predictionPlaceYouWillPay,
        style: PolymarketOrderBlockStyle = .regular,
        payment: PolymarketOrderPaymentRow.Model?,
        isAddFundsEnabled: Bool,
        onAddFunds: @escaping () -> Void,
        @ViewBuilder field: () -> Field,
        @ViewBuilder footer: () -> Footer = { EmptyView() },
        @ViewBuilder bottom: () -> Bottom = { EmptyView() }
    ) {
        self.title = title
        self.style = style
        self.payment = payment
        self.isAddFundsEnabled = isAddFundsEnabled
        self.onAddFunds = onAddFunds
        self.field = field()
        self.footer = footer()
        self.bottom = bottom()
    }

    public var body: some View {
        VStack(spacing: 0) {
            amount

            footer

            if let payment {
                PolymarketOrderBlockSeparator(style: style)

                PolymarketOrderPaymentRow(
                    model: payment,
                    style: style,
                    isAddFundsEnabled: isAddFundsEnabled,
                    onAddFunds: onAddFunds
                )
            }

            bottom
        }
        .background(style.background)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    private var amount: some View {
        VStack(spacing: Constants.captionSpacing) {
            Text(title)
                .style(DesignSystem.Font.subheadingMediumToken, color: titleColor)

            field
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, verticalPadding)
    }

    private var titleColor: Color {
        switch style {
        case .regular: DesignSystem.Color.textTertiary
        case .sheet: DesignSystem.Color.textSecondary
        }
    }

    private var verticalPadding: CGFloat {
        switch style {
        case .regular: Constants.regularVerticalPadding
        case .sheet: Constants.sheetVerticalPadding
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let cornerRadius: CGFloat = 24
    static let captionSpacing: CGFloat = 12
    static let horizontalPadding: CGFloat = 16
    static let regularVerticalPadding: CGFloat = 32
    static let sheetVerticalPadding: CGFloat = 24
}

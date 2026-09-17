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

public struct PolymarketOrderAmountBlock<Field: View, Footer: View>: View {
    private let title: String
    private let payment: PolymarketOrderPaymentRow.Model?
    private let onAddFunds: (() -> Void)?
    private let field: Field
    private let footer: Footer

    public init(
        title: String = Localization.predictionPlaceYouWillPay,
        payment: PolymarketOrderPaymentRow.Model?,
        onAddFunds: (() -> Void)? = nil,
        @ViewBuilder field: () -> Field,
        @ViewBuilder footer: () -> Footer = { EmptyView() }
    ) {
        self.title = title
        self.payment = payment
        self.onAddFunds = onAddFunds
        self.field = field()
        self.footer = footer()
    }

    public var body: some View {
        VStack(spacing: 0) {
            amount

            footer

            if let payment {
                Separator(color: DesignSystem.Color.borderPrimary)

                PolymarketOrderPaymentRow(model: payment, onAddFunds: onAddFunds)
            }
        }
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    private var amount: some View {
        VStack(spacing: Constants.captionSpacing) {
            Text(title)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textTertiary)

            field
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.topPadding)
        .padding(.bottom, Constants.bottomPadding)
    }
}

// MARK: - Constants

private enum Constants {
    static let cornerRadius: CGFloat = 24
    static let captionSpacing: CGFloat = 12
    static let horizontalPadding: CGFloat = 16
    static let topPadding: CGFloat = 32
    static let bottomPadding: CGFloat = 32
}

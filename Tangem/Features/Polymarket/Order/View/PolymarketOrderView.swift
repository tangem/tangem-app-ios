//
//  PolymarketOrderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

struct PolymarketOrderView: View {
    @ObservedObject private var viewModel: PolymarketOrderViewModel

    init(viewModel: PolymarketOrderViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            content

            Spacer(minLength: Constants.contentToButtonGap)

            nextButton
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            Text(Localization.predictionPlaceTitle)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            backButton
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(height: Constants.toolbarHeight)
    }

    private var backButton: some View {
        SwiftUI.Button(action: viewModel.dismiss) {
            DesignSystem.Icons.ChevronLeft.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .frame(size: .init(bothDimensions: Constants.barButtonSide))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .tangemMaterialSurface(in: Circle(), interactive: true, shadow: DesignSystem.Shadow.fallbackButton)
        .accessibilityLabel(Localization.commonBack)
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: Constants.blockSpacing) {
            PolymarketOrderMarketRow(model: viewModel.marketRow)

            PolymarketOrderAmountBlock(payment: viewModel.payment) {
                amountField
            }

            PolymarketOrderSlippageRow(valueText: viewModel.slippageText, onTap: viewModel.openSlippageSelector)
                .background(DesignSystem.Color.bgSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.contentTopPadding)
    }

    private var amountField: some View {
        SendDecimalNumberTextField(viewModel: viewModel.fieldViewModel)
            .prefixSuffixOptions(Constants.prefixSuffixOptions)
            .appearance(.init(
                font: DesignSystem.Font.displayMediumToken.font,
                textColor: DesignSystem.Color.textPrimary,
                placeholderColor: DesignSystem.Color.textTertiary
            ))
            .alignment(.center)
    }

    private var nextButton: some View {
        TangemUI.Button(
            label: Localization.commonNext,
            accessibilityLabel: Localization.commonNext,
            action: viewModel.proceed
        )
        .size(.x12)
        .horizontalLayout(.infinity)
        .disabled(true)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.bottom, Constants.buttonBottomPadding)
    }
}

// MARK: - Constants

private extension PolymarketOrderView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let contentTopPadding: CGFloat = 8
        static let blockSpacing: CGFloat = 12
        static let contentToButtonGap: CGFloat = 24
        static let buttonBottomPadding: CGFloat = 12
        static let cornerRadius: CGFloat = 24
        static let toolbarHeight: CGFloat = 44
        static let barButtonSide: CGFloat = 44

        static let prefixSuffixOptions = SendDecimalNumberTextField.PrefixSuffixOptions
            .prefix(text: AppConstants.usdSign, hasSpace: true)
    }
}

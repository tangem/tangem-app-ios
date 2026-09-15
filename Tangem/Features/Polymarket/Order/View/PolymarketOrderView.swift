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

    @FocusState private var isAmountFocused: Bool

    init(viewModel: PolymarketOrderViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            PolymarketTopBar(
                title: Localization.predictionPlaceTitle,
                onClose: { viewModel.handleViewAction(.closeTapped) }
            )
            .padding(.top, Constants.topBarTopPadding)

            content
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: .zero) { bottomContainer }
        .onWillAppear { viewModel.handleViewAction(.appeared) }
        .onWillDisappear { viewModel.handleViewAction(.disappeared) }
    }

    // MARK: - Bottom

    private var bottomContainer: some View {
        VStack(spacing: 0) {
            nextButton

            keyboardBar
        }
    }

    // MARK: - Content

    private var content: some View {
        GroupedScrollView(contentType: .plain(spacing: Constants.blockSpacing)) {
            PolymarketOrderMarketRow(model: viewModel.marketRow)

            PolymarketOrderAmountBlock(
                payment: viewModel.payment,
                onAddFunds: { viewModel.handleViewAction(.addFundsTapped) }
            ) {
                VStack(spacing: Constants.captionSpacing) {
                    amountField

                    amountCaption
                }
            }

            PolymarketOrderNotificationsView(
                notifications: viewModel.notifications,
                onRetry: { viewModel.handleViewAction(.quoteRetryTapped) }
            )

            PolymarketOrderSlippageRow(
                valueText: viewModel.slippageText,
                onTap: { viewModel.handleViewAction(.slippageTapped) }
            )
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))

            if viewModel.isAwaitingFunds {
                PolymarketOrderNotificationsView(notifications: [.awaitingFunds])
            }
        }
        .horizontalPadding(Constants.horizontalPadding)
        .padding(.top, Constants.contentTopPadding)
        .scrollDismissesKeyboard(.interactively)
        .animation(.easeInOut(duration: Constants.notificationsAnimationDuration), value: viewModel.notifications)
        .animation(.easeInOut(duration: Constants.notificationsAnimationDuration), value: viewModel.isAwaitingFunds)
    }

    @ViewBuilder
    private var amountCaption: some View {
        switch viewModel.amountCaption {
        case .toWin(let text):
            PolymarketAmountBadge.toWin(state: .value(text))
        case .shortfall(let text):
            Text(text)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusError)
                .multilineTextAlignment(.center)
        case nil:
            EmptyView()
        }
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
            .focused($isAmountFocused)
    }

    // MARK: - Keyboard bar

    @ViewBuilder
    private var keyboardBar: some View {
        if isAmountFocused {
            PolymarketAmountFractionChips(
                fractions: viewModel.amountFractions,
                focused: $isAmountFocused,
                onSelect: { viewModel.handleViewAction(.fractionTapped($0)) }
            )
            .transition(.opacity)
        }
    }

    private var nextButton: some View {
        TangemUI.Button(
            label: Localization.commonNext,
            accessibilityLabel: Localization.commonNext,
            action: { viewModel.handleViewAction(.nextTapped) }
        )
        .styleType(.default)
        .size(.x12)
        .horizontalLayout(.infinity)
        .disabled(!viewModel.isNextEnabled)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.buttonTopPadding)
        .padding(.bottom, Constants.buttonBottomPadding)
    }
}

// MARK: - Constants

private extension PolymarketOrderView {
    enum Constants {
        static let topBarTopPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 16
        static let contentTopPadding: CGFloat = 16
        static let blockSpacing: CGFloat = 8
        static let captionSpacing: CGFloat = 8
        static let buttonTopPadding: CGFloat = 12
        static let buttonBottomPadding: CGFloat = 12
        static let notificationsAnimationDuration: TimeInterval = 0.3
        static let cornerRadius: CGFloat = 24

        static let prefixSuffixOptions = SendDecimalNumberTextField.PrefixSuffixOptions
            .prefix(text: AppConstants.usdSign, hasSpace: true)
    }
}

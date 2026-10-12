//
//  PolymarketOrderSummaryView.swift
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

struct PolymarketOrderSummaryView: View {
    @ObservedObject private var viewModel: PolymarketOrderSummaryViewModel

    init(viewModel: PolymarketOrderSummaryViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            PolymarketTopBar(
                title: viewModel.screenTitle,
                onBack: { viewModel.handleViewAction(.goBack) },
                onClose: { viewModel.handleViewAction(.close) }
            )
            .padding(.top, Constants.topBarTopPadding)

            content
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: .zero) { footer }
        .onWillAppear { viewModel.handleViewAction(.onAppear) }
        .bindAlert($viewModel.alert)
        .onWillDisappear { viewModel.handleViewAction(.onDisappear) }
    }

    // MARK: - Content

    private var content: some View {
        GroupedScrollView(contentType: .plain(spacing: Constants.blockSpacing)) {
            PolymarketOrderSummaryHeader(model: viewModel.header)

            PolymarketOrderMarketRow(model: viewModel.marketRow)

            PolymarketOrderDetailsBlock(
                currencyCode: viewModel.currencyCode,
                feeText: viewModel.feeText,
                slippageText: viewModel.slippageText,
                onFeeTap: viewModel.isFeeBreakdownAvailable ? { viewModel.handleViewAction(.openFeeBreakdown) } : nil
            )

            PolymarketOrderNotificationsView(notifications: viewModel.notifications)
        }
        .horizontalPadding(Constants.horizontalPadding)
        .padding(.top, Constants.contentTopPadding)
        .animation(.easeInOut(duration: Constants.notificationsAnimationDuration), value: viewModel.notifications)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: Constants.footerSpacing) {
            PolymarketLegalLine { viewModel.handleViewAction(.openLegalTerms($0)) }

            placeButton
        }
        .padding(.horizontal, Constants.footerHorizontalPadding)
        .padding(.vertical, Constants.footerVerticalPadding)
        .background {
            Fade(position: .bottom)
                .blurred()
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var placeButton: some View {
        TangemUI.Button(
            label: viewModel.primaryActionTitle,
            accessibilityLabel: viewModel.primaryActionTitle,
            action: { viewModel.handleViewAction(.placeOrder) }
        )
        .iconEnd(DesignSystem.Icons.LogoTangem.regular24)
        .styleType(.primary)
        .size(.x12)
        .horizontalLayout(.infinity)
        .loading(.spinner(if: viewModel.isPlacing))
        .disabled(!viewModel.isPlaceEnabled)
    }
}

// MARK: - Constants

private extension PolymarketOrderSummaryView {
    enum Constants {
        static let topBarTopPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 16
        static let contentTopPadding: CGFloat = 16
        static let blockSpacing: CGFloat = 8
        static let footerSpacing: CGFloat = 12
        static let footerHorizontalPadding: CGFloat = 24
        static let footerVerticalPadding: CGFloat = 12
        static let notificationsAnimationDuration: TimeInterval = 0.3
    }
}

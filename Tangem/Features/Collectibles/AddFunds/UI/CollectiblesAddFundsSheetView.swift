//
//  CollectiblesAddFundsSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct CollectiblesAddFundsSheetView: View {
    @ObservedObject var viewModel: CollectiblesAddFundsSheetViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, Metrics.horizontalPadding)

            options
                .padding(.top, Metrics.optionsTopPadding)
        }
        .padding(.top, Metrics.topPadding)
        .padding(.bottom, Metrics.bottomPadding)
    }
}

// MARK: - Content

private extension CollectiblesAddFundsSheetView {
    // MARK: - View properties

    var header: some View {
        BottomSheetHeaderView(title: Localization.commonAddFunds, trailing: { closeButton })
            .titleFont(DesignSystem.Font.bodyMediumToken.font)
            .titleColor(DesignSystem.Color.textPrimary)
    }

    var closeButton: some View {
        TangemUI.Button(
            icon: DesignSystem.Icons.Cross.regular20,
            accessibilityLabel: Localization.commonClose,
            action: viewModel.close
        )
        .size(.x11)
        .styleType(.material(.glass))
    }

    var options: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.options) { option in
                SwiftUI.Button { viewModel.select(option) } label: {
                    Row(title: option.title, subtitle: option.subtitle)
                        .start { icon(option.icon) }
                }
                .buttonStyle(.plain)
            }
        }
    }

    func icon(_ icon: ImageType) -> some View {
        icon.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconBrand)
            .frame(size: CGSize(bothDimensions: Metrics.iconSize))
            .background(DesignSystem.Color.bgStatusInfoSubtle, in: Circle())
            .accessibilityHidden(true)
    }
}

// MARK: - Metrics

extension CollectiblesAddFundsSheetView {
    enum Metrics {
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 4
        static let bottomPadding: CGFloat = 8
        static let optionsTopPadding: CGFloat = 12
        static let iconSize: CGFloat = 40
        static let estimatedHeight: CGFloat = 250
    }
}

// MARK: - Option presentation

private extension CollectiblesAddFundsSheetViewModel.Option {
    var title: String {
        switch self {
        case .swap: Localization.tangempayTopupSwapTitle
        case .receive: Localization.tangempayTopupReceiveTitle
        }
    }

    var subtitle: String {
        // [REDACTED_TODO_COMMENT]
        switch self {
        case .swap: "Use crypto from your wallet to top-up your Packs account"
        case .receive: "Send USDC Solana to your account's address"
        }
    }

    var icon: ImageType {
        switch self {
        case .swap: DesignSystem.Icons.LogoTangem.regular20
        case .receive: DesignSystem.Icons.Grid.regular20
        }
    }
}

//
//  TangemPayAddFundsSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayAddFundsSheetView: View {
    @ObservedObject var viewModel: TangemPayAddFundsSheetViewModel

    var body: some View {
        if FeatureProvider.isAvailable(.tangemPaySpendRedesign) {
            redesignedBody
        } else {
            legacyBody
        }
    }
}

// MARK: - Redesigned

private extension TangemPayAddFundsSheetView {
    var redesignedBody: some View {
        VStack(spacing: .zero) {
            header

            options
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    var header: some View {
        BottomSheetHeaderView(title: Localization.tangempayCardDetailsAddFunds, trailing: {
            closeButton
        })
        .titleFont(DesignSystem.Font.bodyMediumToken.font)
        .titleColor(DesignSystem.Color.textPrimary)
    }

    var options: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.options) { option in
                TangemPayAddFundsSheetOptionView(option: option, action: {
                    viewModel.userDidTapOption(option: option)
                })
            }
        }
    }

    var closeButton: some View {
        TangemButtonV2(icon: DesignSystem.Icons.Cross.regular20, accessibilityLabel: Localization.commonClose, action: viewModel.close)
            .size(.x11)
            .styleType(.material(.glass))
    }
}

// MARK: - Legacy

private extension TangemPayAddFundsSheetView {
    var legacyBody: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(title: Localization.tangempayCardDetailsAddFunds, trailing: {
                NavigationBarButton.close(action: viewModel.close)
            })

            GroupedSection(viewModel.options) { option in
                TangemPayAddFundsSheetOptionView(option: option, action: {
                    viewModel.userDidTapOption(option: option)
                })
            } header: {
                DefaultHeaderView(Localization.tangempayCardDetailsAddFundsSubtitle)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }
            .backgroundColor(Colors.Background.action)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.tertiary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

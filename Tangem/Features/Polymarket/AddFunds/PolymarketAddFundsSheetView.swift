//
//  PolymarketAddFundsSheetView.swift
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

struct PolymarketAddFundsSheetView: View {
    @ObservedObject var viewModel: PolymarketAddFundsSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            header

            options
        }
        .padding([.horizontal, .bottom], 16)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackground = .color(DesignSystem.Color.bgSecondary)
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
        .alert(item: $viewModel.alert) { $0.alert }
    }
}

// MARK: - Subviews

private extension PolymarketAddFundsSheetView {
    var header: some View {
        BottomSheetHeaderView(title: Localization.commonAddFunds, trailing: {
            closeButton
        })
        .titleFont(DesignSystem.Font.bodyMediumToken.font)
        .titleColor(DesignSystem.Color.textPrimary)
    }

    var options: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.options) { option in
                PolymarketAddFundsSheetOptionView(option: option, action: {
                    viewModel.userDidTapOption(option)
                })
            }
        }
    }

    var closeButton: some View {
        TangemUI.Button(icon: DesignSystem.Icons.Cross.regular20, accessibilityLabel: Localization.commonClose, action: viewModel.close)
            .size(.x11)
            .styleType(.material(.glass))
    }
}

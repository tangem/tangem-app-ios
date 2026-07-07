//
//  AddressBookWalletPickerProxyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization
import TangemAssets

struct AddressBookWalletPickerProxyView: View {
    let viewModel: AddressBookWalletPickerViewModel

    var body: some View {
        FloatingSheetContentWithHeader(
            headerConfig: .init(
                title: Localization.commonChooseWallet,
                backAction: nil,
                closeAction: viewModel.close
            )
        ) {
            VStack(spacing: 12) {
                walletList
                cancelButton
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .floatingSheetConfiguration { config in
            config.sheetBackgroundColor = DesignSystem.Color.bgPrimary
        }
    }

    private var walletList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.itemViewModels) { itemViewModel in
                WalletSelectorItemView(viewModel: itemViewModel)
            }
        }
        .defaultRoundedBackground(
            with: DesignSystem.Color.bgSecondary,
            verticalPadding: .zero,
            cornerRadius: 20
        )
    }

    private var cancelButton: some View {
        TangemButtonV2(
            label: AttributedString(Localization.commonCancel),
            accessibilityLabel: Localization.commonCancel,
            action: viewModel.close
        )
        .styleType(.secondary)
        .size(.x12)
        .horizontalLayout(.infinity)
    }
}

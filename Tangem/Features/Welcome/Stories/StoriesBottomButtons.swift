//
//  StoriesBottomButtons.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct StoriesBottomButtons: View {
    let isScanning: Bool
    let createWallet: () -> Void
    let scanCard: () -> Void
    let orderCard: () -> Void
    let scanTroubleShootingDialog: Binding<ConfirmationDialogViewModel?>

    var body: some View {
        createWalletButton
            .confirmationDialog(viewModel: scanTroubleShootingDialog)
    }
}

// MARK: - Subviews

private extension StoriesBottomButtons {
    var createWalletButton: some View {
        MainButton(
            title: Localization.commonGetStarted,
            style: .primary,
            isDisabled: isScanning,
            action: createWallet
        )
        .accessibilityIdentifier(StoriesAccessibilityIdentifiers.getStartedButton)
    }

    var scanCardButton: some View {
        MainButton(
            title: Localization.homeButtonScan,
            icon: .trailing(Assets.tangemIcon),
            style: .secondary,
            isLoading: isScanning,
            action: scanCard
        )
        .accessibilityIdentifier(StoriesAccessibilityIdentifiers.scanButton)
    }

    var orderCardButton: some View {
        MainButton(
            title: Localization.homeButtonOrder,
            style: .secondary,
            isDisabled: isScanning,
            action: orderCard
        )
    }
}

struct StoriesBottomButtons_Previews: PreviewProvider {
    static var previews: some View {
        StoriesBottomButtons(
            isScanning: false,
            createWallet: {},
            scanCard: {},
            orderCard: {},
            scanTroubleShootingDialog: .constant(nil)
        )
    }
}

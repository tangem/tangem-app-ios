//
//  StoriesBottomButtons.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct StoriesBottomButtons: View {
    let isScanning: Bool
    let createWallet: () -> Void
    let scanCard: () -> Void
    let orderCard: () -> Void

    private let isMobileWalletEnabled = FeatureProvider.isAvailable(.mobileWallet)

    private var scanColorStyle: MainButton.Style {
        isMobileWalletEnabled ? .secondary : .primary
    }

    var body: some View {
        if isMobileWalletEnabled {
            createWalletButton
        } else {
            HStack {
                scanCardButton
                orderCardButton
            }
        }
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
            style: scanColorStyle,
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
            orderCard: {}
        )
    }
}

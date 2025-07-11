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
    var isScanning: Bool

    let createWallet: () -> Void
    let importWallet: () -> Void
    let scanCard: () -> Void
    let orderCard: () -> Void

    private let isHotWalletEnabled = FeatureProvider.isAvailable(.hotWallet)

    private let createColorStyle: MainButton.Style = .primary
    private let importColorStyle: MainButton.Style = .secondary
    private let orderColorStyle: MainButton.Style = .secondary

    private var scanColorStyle: MainButton.Style {
        isHotWalletEnabled ? .secondary : .primary
    }

    var body: some View {
        if isHotWalletEnabled {
            VStack(spacing: 8) {
                createWalletButton
                importWalletButton
                scanCardButton
            }
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
            title: Localization.homeButtonCreateNewWallet,
            style: createColorStyle,
            isDisabled: isScanning,
            action: createWallet
        )
    }

    var importWalletButton: some View {
        MainButton(
            title: Localization.homeButtonAddExistingWallet,
            style: importColorStyle,
            isDisabled: isScanning,
            action: importWallet
        )
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
            style: orderColorStyle,
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
            importWallet: {},
            scanCard: {},
            orderCard: {}
        )
    }
}

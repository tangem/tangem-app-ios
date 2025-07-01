//
//  WalletConnectSolanaBlockchainWarningViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct TangemAssets.ImageType
import TangemLocalization

struct WalletConnectSolanaBlockchainWarningViewState {
    let iconAsset: ImageType
    let title = "Solana Transaction Limitation"
    let body = "Some Solana transactions may exceed the capabilities of your Tangem card, resulting in possible failures when signing."

    let cancelButton = Button(title: Localization.commonCancel, isLoading: false)
    var connectAnywayButton = Button(title: Localization.wcAlertConnectAnyway, isLoading: false)
}

extension WalletConnectSolanaBlockchainWarningViewState {
    struct Button {
        let title: String
        var isLoading: Bool
    }
}

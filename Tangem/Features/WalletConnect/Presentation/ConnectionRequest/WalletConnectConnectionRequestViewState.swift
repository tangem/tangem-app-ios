//
//  WalletConnectConnectionRequestViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import TangemAssets
import TangemLocalization

struct WalletConnectConnectionRequestViewState {
    let navigationTitle = Localization.wcWalletConnect

    let connectionRequestRowLabel: String
    let walletRowLabel = Localization.wcCommonWallet
    let networksRowLabel = Localization.wcCommonNetworks
}

extension WalletConnectConnectionRequestViewState {
    enum ContentState {
        case loading
        case content
    }

    struct DAppDescriptionSection {
        let id: Int
        let iconURL: URL?
        let fallbackIconAsset = Assets.Glyphs.explore
        let name: String
        let domain: String
    }

    struct LoadingContentState {
        let connectionRequestRowLabel = "Connecting"
    }
}

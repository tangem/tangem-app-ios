//
//  WalletConnectConnectedDAppDetailsViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import TangemAssets
import TangemLocalization

// [REDACTED_TODO_COMMENT]
// [REDACTED_TODO_COMMENT]
struct WalletConnectConnectedDAppDetailsViewState {
    let navigationBar: NavigationBar
    let dAppDescriptionSection: DAppDescriptionSection
    let walletSection: WalletSection?
    let connectedNetworksSection: ConnectedNetworksSection?
    var disconnectButton = DisconnectButton(isLoading: false)
}

extension WalletConnectConnectedDAppDetailsViewState {
    struct NavigationBar {
        let title = "Connected App"
        let connectedTime: String?
    }

    struct DAppDescriptionSection {
        let id: Int
        let iconURL: URL?
        let fallbackIconAsset = Assets.Glyphs.explore
        let name: String
        let domain: String
    }

    struct WalletSection {
        let labelAsset = Assets.Glyphs.walletNew
        let labelText = Localization.wcCommonWallet
        let walletName: String

        init?(walletName: String?) {
            guard let walletName else { return nil }
            self.walletName = walletName
        }
    }

    struct ConnectedNetworksSection {
        let title = "Connected networks"
        let blockchains: [BlockchainRowItem]

        init?(blockchains: [BlockchainRowItem]) {
            guard !blockchains.isEmpty else { return nil }
            self.blockchains = blockchains
        }
    }

    struct DisconnectButton {
        let title = Localization.commonDisconnect
        var isLoading: Bool
    }

    struct BlockchainRowItem: Identifiable {
        let id: String
        let asset: ImageType
        let name: String
        let currencySymbol: String
    }
}

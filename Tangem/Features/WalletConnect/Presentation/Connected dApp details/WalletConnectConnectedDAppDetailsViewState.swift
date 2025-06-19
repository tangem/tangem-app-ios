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
enum WalletConnectConnectedDAppDetailsViewState {
    case dAppDetails(DAppDetails)
    case verifiedDomain(WalletConnectDAppDomainVerificationViewModel)
}

extension WalletConnectConnectedDAppDetailsViewState {
    struct DAppDetails {
        let navigationBar: NavigationBar
        let dAppDescriptionSection: WalletConnectDAppDescriptionViewModel
        let walletSection: WalletSection?
        let dAppVerificationWarningSection: WalletConnectWarningNotificationViewModel?
        let connectedNetworksSection: ConnectedNetworksSection?
        var disconnectButton = DisconnectButton(isLoading: false)
    }
}

extension WalletConnectConnectedDAppDetailsViewState.DAppDetails {
    struct NavigationBar {
        let title = "Connected App"
        let connectedTime: String?
    }

    struct WalletSection {
        let labelAsset = Assets.Glyphs.walletNew
        let labelText = Localization.wcCommonWallet
        let walletName: String
    }

    struct ConnectedNetworksSection {
        let headerTitle = "Connected networks"
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
        let iconAsset: ImageType
        let name: String
        let currencySymbol: String
    }
}

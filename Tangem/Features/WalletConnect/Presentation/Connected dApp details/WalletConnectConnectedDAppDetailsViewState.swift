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
enum WalletConnectConnectedDAppDetailsViewState: Equatable {
    case dAppDetails(DAppDetails)
    case verifiedDomain(WalletConnectDAppDomainVerificationViewModel)

    static func == (lhs: WalletConnectConnectedDAppDetailsViewState, rhs: WalletConnectConnectedDAppDetailsViewState) -> Bool {
        switch (lhs, rhs) {
        case (.dAppDetails(let lhsDAppDetails), .dAppDetails(let rhsDAppDetails)):
            return lhsDAppDetails == rhsDAppDetails

        case (.verifiedDomain, .verifiedDomain):
            return true

        default:
            return false
        }
    }
}

extension WalletConnectConnectedDAppDetailsViewState {
    struct DAppDetails: Equatable {
        var navigationBar: NavigationBar
        let dAppDescriptionSection: WalletConnectDAppDescriptionViewModel
        let walletSection: WalletSection?
        let dAppVerificationWarningSection: WalletConnectWarningNotificationViewModel?
        let connectedNetworksSection: ConnectedNetworksSection?
        var disconnectButton = DisconnectButton(isLoading: false)
    }
}

extension WalletConnectConnectedDAppDetailsViewState.DAppDetails {
    struct NavigationBar: Equatable {
        let title = "Connected App"
        var connectedTime: String
    }

    struct WalletSection: Equatable {
        let labelAsset = Assets.Glyphs.walletNew
        let labelText = Localization.wcCommonWallet
        let walletName: String
    }

    struct ConnectedNetworksSection: Equatable {
        let headerTitle = "Connected networks"
        let blockchains: [BlockchainRowItem]

        init?(blockchains: [BlockchainRowItem]) {
            guard !blockchains.isEmpty else { return nil }
            self.blockchains = blockchains
        }
    }

    struct DisconnectButton: Equatable {
        let title = Localization.commonDisconnect
        var isLoading: Bool
    }

    struct BlockchainRowItem: Identifiable, Equatable {
        let id: String
        let iconAsset: ImageType
        let name: String
        let currencySymbol: String
    }
}

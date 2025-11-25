
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
import TangemUI

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
        let dAppDescriptionSection: EntitySummaryView.ViewState
        let walletSection: WalletSection?
        let connectionTargetSection: ConnectionTargetSection?
        let dAppVerificationWarningSection: WalletConnectWarningNotificationViewModel?
        let connectedNetworksSection: ConnectedNetworksSection?
        var disconnectButton = DisconnectButton(isLoading: false)
    }
}

extension WalletConnectConnectedDAppDetailsViewState.DAppDetails {
    struct NavigationBar: Equatable {
        let title = Localization.wcConnectedAppTitle
        var connectedTime: String
    }

    struct ConnectionTargetSection: Equatable {
        let iconAsset = Assets.Glyphs.walletNew
        let targetName: String
        let target: Target

        init(targetName: String, target: Target) {
            self.targetName = targetName
            self.target = target
        }
    }

    struct WalletSection: Equatable {
        let labelAsset = Assets.Glyphs.walletNew
        let labelText = Localization.wcCommonWallet
        let walletName: String
    }

    struct ConnectedNetworksSection: Equatable {
        let headerTitle = Localization.wcConnectedNetworks
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

extension WalletConnectConnectedDAppDetailsViewState.DAppDetails.ConnectionTargetSection {
    enum Target: Equatable {
        case wallet(WCWalletTarget = WCWalletTarget())
        case account(WCAccountTarget)

        struct WCWalletTarget: Equatable {
            let label = Localization.wcCommonWallet
        }

        struct WCAccountTarget: Equatable {
            let label = Localization.accountDetailsTitle
            let icon: AccountModel.Icon
        }
    }
}

//
//  WalletConnectNetworksSelectorViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

// [REDACTED_TODO_COMMENT]
struct WalletConnectNetworksSelectorViewState {
    let navigationBarTitle = "Choose network"

    var requiredNetworksAreUnavailableSection: RequiredNetworksAreUnavailableSection?
    var availableSection: AvailableSection
    var notAddedSection: NotAddedSection

    let doneButtonTitle = Localization.commonDone
}

extension WalletConnectNetworksSelectorViewState {
    struct BlockchainViewState {
        let iconAsset: ImageType
        let blockchainName: String
        let blockchainCurrency: String
    }
}

extension WalletConnectNetworksSelectorViewState {
    struct RequiredNetworksAreUnavailableSection {
        let notificationViewModel: WalletConnectWarningNotificationViewModel
        let blockchains: [BlockchainViewState]
        let requiredLabel = "Required"
    }
}

// MARK: - Available section

extension WalletConnectNetworksSelectorViewState {
    struct AvailableSection {
        let headerTitle = "Available networks"
        var blockchains: [AvailableBlockchain]
    }
}

extension WalletConnectNetworksSelectorViewState.AvailableSection {
    struct OptionalBlockchain {
        let blockchain: BlockchainViewState
        var isSelected: Bool
    }

    enum AvailableBlockchain {
        case required(BlockchainViewState)
        case optional(OptionalBlockchain)
    }
}

// MARK: - Not added section

extension WalletConnectNetworksSelectorViewState {
    struct NotAddedSection {
        let headerTitle = "Not Added"
        var blockchains: [BlockchainViewState]
    }
}

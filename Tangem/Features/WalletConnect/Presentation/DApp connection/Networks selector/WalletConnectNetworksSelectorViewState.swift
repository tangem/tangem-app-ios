//
//  WalletConnectNetworksSelectorViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain
import TangemAssets
import TangemLocalization

// [REDACTED_TODO_COMMENT]
struct WalletConnectNetworksSelectorViewState {
    let navigationBarTitle = "Choose network"

    var requiredNetworksAreUnavailableSection: RequiredNetworksAreUnavailableSection?
    var availableSection: AvailableSection
    var notAddedSection: NotAddedSection

    var doneButton: DoneButton
}

extension WalletConnectNetworksSelectorViewState {
    struct BlockchainViewState: Identifiable {
        let domainModel: Blockchain

        let id: String
        let iconAsset: ImageType
        let name: String
        let currencySymbol: String
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
        let blockchain: WalletConnectNetworksSelectorViewState.BlockchainViewState
        var isSelected: Bool
    }

    enum AvailableBlockchain: Identifiable {
        case required(WalletConnectNetworksSelectorViewState.BlockchainViewState)
        case optional(OptionalBlockchain)

        var id: String {
            blockchainViewState.id
        }

        var blockchainViewState: WalletConnectNetworksSelectorViewState.BlockchainViewState {
            switch self {
            case .required(let blockchainViewState):
                blockchainViewState

            case .optional(let optionalBlockchain):
                optionalBlockchain.blockchain
            }
        }

        var isReadOnly: Bool {
            switch self {
            case .required:
                true

            case .optional:
                false
            }
        }

        var isSelected: Bool {
            switch self {
            case .required:
                true

            case .optional(let optionalBlockchain):
                optionalBlockchain.isSelected
            }
        }
    }
}

// MARK: - Not added section

extension WalletConnectNetworksSelectorViewState {
    struct NotAddedSection {
        let headerTitle = "Not Added"
        var blockchains: [BlockchainViewState]
    }
}

extension WalletConnectNetworksSelectorViewState {
    struct DoneButton {
        let title = Localization.commonDone
        var isEnabled: Bool
    }
}

//
//  WalletConnectNetworksSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import enum BlockchainSdk.Blockchain

@MainActor
final class WalletConnectNetworksSelectorViewModel: ObservableObject {
    private let backAction: () -> Void
    private let doneAction: ([Blockchain]) -> Void

    @Published private(set) var state: WalletConnectNetworksSelectorViewState

    init(
        backAction: @escaping () -> Void,
        doneAction: @escaping ([Blockchain]) -> Void
    ) {
        state = .initial
        self.backAction = backAction
        self.doneAction = doneAction
    }

    func update(with blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult) {
        state = .init(blockchainsAvailabilityResult)
    }
}

// MARK: - View events handling

extension WalletConnectNetworksSelectorViewModel {
    func handle(viewEvent: WalletConnectNetworksSelectorViewEvent) {
        switch viewEvent {
        case .navigationBackButtonTapped:
            backAction()

        case .optionalBlockchainSelectionChanged(let index, let isSelected):
            state.availableSection.blockchains[index].updateSelection(isSelected)
            state.doneButton.isEnabled = state.requiredNetworksAreUnavailableSection == nil
                && state.availableSection.blockchains.filter(\.isSelected).isNotEmpty

        case .doneButtonTapped:
            doneAction(state.retrieveSelectedBlockchains())
        }
    }
}

// MARK: - State updates and mapping

private extension WalletConnectNetworksSelectorViewState {
    init(_ blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult) {
        self.init(
            requiredNetworksAreUnavailableSection: .init(blockchainsAvailabilityResult),
            availableSection: .init(blockchainsAvailabilityResult),
            notAddedSection: .init(blockchainsAvailabilityResult),
            doneButton: .init(
                isEnabled: blockchainsAvailabilityResult.unavailableRequiredBlockchains.isEmpty
                    && !blockchainsAvailabilityResult.availableBlockchains.filter(\.isSelected).isEmpty
            )
        )
    }

    static let initial = WalletConnectNetworksSelectorViewState(
        requiredNetworksAreUnavailableSection: nil,
        availableSection: .init(blockchains: []),
        notAddedSection: .init(blockchains: []),
        doneButton: .init(isEnabled: false)
    )

    func retrieveSelectedBlockchains() -> [Blockchain] {
        availableSection.blockchains.compactMap(\.selectedBlockchain)
    }
}

private extension WalletConnectNetworksSelectorViewState.RequiredNetworksAreUnavailableSection {
    init?(_ result: WalletConnectDAppBlockchainsAvailabilityResult) {
        let missingBlockchains = result.unavailableRequiredBlockchains

        guard !missingBlockchains.isEmpty else {
            return nil
        }

        self.init(
            notificationViewModel: .requiredNetworksAreUnavailableForSelectedWallet(missingBlockchains.map(\.displayName)),
            blockchains: missingBlockchains.map { domainBlockchain in
                WalletConnectNetworksSelectorViewState.BlockchainViewState(domainBlockchain: domainBlockchain, isFilled: false)
            }
        )
    }
}

private extension WalletConnectNetworksSelectorViewState.AvailableSection {
    init(_ result: WalletConnectDAppBlockchainsAvailabilityResult) {
        self.init(
            blockchains: result
                .availableBlockchains
                .map(WalletConnectNetworksSelectorViewState.AvailableSection.AvailableBlockchain.init)
        )
    }

    var selectedBlockchains: [Blockchain] {
        blockchains.compactMap(\.selectedBlockchain)
    }
}

private extension WalletConnectNetworksSelectorViewState.AvailableSection.AvailableBlockchain {
    init(_ availableBlockchain: WalletConnectDAppBlockchainsAvailabilityResult.AvailableBlockchain) {
        switch availableBlockchain {
        case .optional(let optionalBlockchain):
            self = .optional(.init(optionalBlockchain))

        case .required(let domainBlockchain):
            self = .required(
                WalletConnectNetworksSelectorViewState.BlockchainViewState(
                    domainBlockchain: domainBlockchain,
                    isFilled: true
                )
            )
        }
    }

    var selectedBlockchain: BlockchainSdk.Blockchain? {
        switch self {
        case .optional(let optionalBlockchain) where optionalBlockchain.isSelected:
            optionalBlockchain.blockchain.domainModel

        case .optional:
            nil

        case .required(let blockchainViewState):
            blockchainViewState.domainModel
        }
    }

    mutating func updateSelection(_ isSelected: Bool) {
        switch self {
        case .required:
            assertionFailure("Attempt of deselecting required blockchain. State is invalid. Developer mistake.")

        case .optional(var optionalBlockchain):
            optionalBlockchain.isSelected = isSelected
            self = .optional(optionalBlockchain)
        }
    }
}

private extension WalletConnectNetworksSelectorViewState.AvailableSection.OptionalBlockchain {
    init(_ optionalBlockchain: WalletConnectDAppBlockchainsAvailabilityResult.OptionalBlockchain) {
        self.init(
            blockchain: WalletConnectNetworksSelectorViewState.BlockchainViewState(
                domainBlockchain: optionalBlockchain.blockchain,
                isFilled: true
            ),
            isSelected: optionalBlockchain.isSelected
        )
    }
}

private extension WalletConnectNetworksSelectorViewState.NotAddedSection {
    init(_ result: WalletConnectDAppBlockchainsAvailabilityResult) {
        self.init(
            blockchains: result.notAddedBlockchains.map { domainBlockchain in
                WalletConnectNetworksSelectorViewState.BlockchainViewState(domainBlockchain: domainBlockchain, isFilled: false)
            }
        )
    }
}

private extension WalletConnectNetworksSelectorViewState.BlockchainViewState {
    init(domainBlockchain: Blockchain, isFilled: Bool) {
        domainModel = domainBlockchain
        iconAsset = NetworkImageProvider().provide(by: domainBlockchain, filled: isFilled)
        id = domainBlockchain.networkId
        name = domainBlockchain.displayName
        currencySymbol = domainBlockchain.currencySymbol
    }
}

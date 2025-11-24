//
//  MarketsNetworkSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI
import BlockchainSdk

final class MarketsNetworkSelectorViewModel: FloatingSheetContentViewModel {
    private(set) var tokenItemViewModels: [MarketsNetworkSelectorItemViewModel] = []

    private let coinName: String
    private let coinSymbol: String
    private let coinId: String
    private let networks: [NetworkModel]
    private let supportedBlockchains: Set<Blockchain>
    private let selectedAccount: any CryptoAccountModel
    private let onSelectNetwork: ((TokenItem) -> Void)?

    init(
        data: MarketsTokensNetworkSelectorViewModel.InputData,
        selectedUserWalletConfig: UserWalletConfig,
        selectedAccount: any CryptoAccountModel,
        onSelectNetwork: ((TokenItem) -> Void)? = nil
    ) {
        coinId = data.coinId
        coinName = data.coinName
        coinSymbol = data.coinSymbol
        networks = data.networks

        supportedBlockchains = selectedUserWalletConfig.supportedBlockchains
        self.selectedAccount = selectedAccount
        self.onSelectNetwork = onSelectNetwork

        tokenItemViewModels = tokenItems
            .enumerated()
            .map { [weak self] index, element in
                MarketsNetworkSelectorItemViewModel(
                    tokenItem: element,
                    isReadonly: self?.isAdded(element) ?? false,
                    onTap: { [weak self] in
                        self?.handleNetworkSelection(element)
                    }
                )
            }
    }

    private func handleNetworkSelection(_ tokenItem: TokenItem) {
        // Don't allow selection if already added
        guard !isAdded(tokenItem) else { return }

        onSelectNetwork?(tokenItem)
    }

    private var tokenItems: [TokenItem] {
        MarketsTokenItemsProvider.calculateTokenItems(
            coinId: coinId,
            coinName: coinName,
            coinSymbol: coinSymbol,
            networks: networks,
            supportedBlockchains: supportedBlockchains,
            cryptoAccount: selectedAccount
        )
    }

    private func isAdded(_ tokenItem: TokenItem) -> Bool {
        selectedAccount.userTokensManager.contains(tokenItem, derivationInsensitive: false)
    }
}

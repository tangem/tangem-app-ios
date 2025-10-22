//
//  MarketsNetworkSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

final class MarketsNetworkSelectorViewModel: FloatingSheetContentViewModel {
    private(set) var tokenItemViewModels: [MarketsNetworkSelectorItemViewModel] = []

    private let coinName: String
    private let coinSymbol: String
    private let coinId: String
    private let networks: [NetworkModel]
    private let selectedUserWalletModel: UserWalletModel?
    private let selectedAccount: any CryptoAccountModel

    init(
        data: MarketsTokensNetworkSelectorViewModel.InputData,
        selectedUserWalletModel: UserWalletModel?,
        selectedAccount: any CryptoAccountModel
    ) {
        coinId = data.coinId
        coinName = data.coinName
        coinSymbol = data.coinSymbol
        networks = data.networks

        self.selectedUserWalletModel = selectedUserWalletModel
        self.selectedAccount = selectedAccount

        tokenItemViewModels = tokenItems
            .enumerated()
            .map { index, element in
                MarketsNetworkSelectorItemViewModel(
                    tokenItem: element,
                    isReadonly: isAdded(element),
                )
            }
    }

    private var tokenItems: [TokenItem] {
        guard let selectedUserWalletModel else {
            return []
        }

        let supportedBlockchains = if !selectedAccount.isMainAccount {
            selectedUserWalletModel.config.supportedBlockchains
                .filter { AccountDerivationPathHelper(blockchain: $0).areAccountsAvailableForBlockchain() }
        } else {
            selectedUserWalletModel.config.supportedBlockchains
        }

        let tokenItemMapper = TokenItemMapper(supportedBlockchains: supportedBlockchains)

        let tokenItems = networks
            .compactMap {
                tokenItemMapper.mapToTokenItem(id: coinId, name: coinName, symbol: coinSymbol, network: $0)
            }
            .sorted { lhs, rhs in
                // Main networks must be up list networks
                lhs.isBlockchain && lhs.isBlockchain != rhs.isBlockchain
            }

        return tokenItems
    }

    private func isAdded(_ tokenItem: TokenItem) -> Bool {
        selectedAccount.userTokensManager.contains(tokenItem)
    }
}

//
//  SwapOfferedTokensViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import SwiftUI
import TangemUI

final class SwapOfferedTokensViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published private(set) var rows: [RowViewData] = []

    private let tokenItems: [TokenItem]
    private weak var additionCoordinator: SwapMarketsTokenAdditionRoutable?

    private var displayedWalletId: String?
    private var walletSubscription: AnyCancellable?

    init(tokenItems: [TokenItem], additionCoordinator: SwapMarketsTokenAdditionRoutable) {
        self.tokenItems = tokenItems
        self.additionCoordinator = additionCoordinator

        resolveRows()
    }

    func setup(displayedWalletIdPublisher: some Publisher<String?, Never>) {
        walletSubscription = displayedWalletIdPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, walletId in
                viewModel.displayedWalletId = walletId
                viewModel.resolveRows()
            }
    }

    @MainActor
    func addToken(_ tokenItem: TokenItem) {
        guard let inputData = makeAddTokenInputData(for: tokenItem) else {
            return
        }

        additionCoordinator?.requestAddToken(inputData: inputData)
    }
}

// MARK: - Rows

extension SwapOfferedTokensViewModel {
    struct RowViewData: Identifiable {
        let tokenItem: TokenItem
        let iconInfo: TokenIconInfo
        let name: String
        let symbol: String
        let networkName: String

        var id: TokenItem { tokenItem }
    }
}

// MARK: - Private implementation

private extension SwapOfferedTokensViewModel {
    var displayedWalletModel: (any UserWalletModel)? {
        userWalletRepository.models.first { $0.userWalletId.stringValue == displayedWalletId }
            ?? userWalletRepository.selectedModel
    }

    func resolveRows() {
        guard let userWalletModel = displayedWalletModel else {
            rows = []
            return
        }

        let accounts = AccountModelsAggregator(.crypto, .joint).models(from: userWalletModel.accountModelsManager)

        let resolved = tokenItems.compactMap { tokenItem -> RowViewData? in
            let isAlreadyAdded = accounts.contains {
                $0.userTokensManager.contains(tokenItem, derivationInsensitive: true)
            }

            guard !isAlreadyAdded else {
                return nil
            }

            return RowViewData(
                tokenItem: tokenItem,
                iconInfo: TokenIconInfoBuilder().build(from: tokenItem, isCustom: false),
                name: tokenItem.name,
                symbol: tokenItem.currencySymbol,
                networkName: tokenItem.networkName
            )
        }

        withTransaction(.withoutAnimations()) {
            rows = resolved
        }
    }

    func makeAddTokenInputData(for tokenItem: TokenItem) -> ExpressAddTokenInputData? {
        guard let coinId = tokenItem.id, let contractAddress = tokenItem.contractAddress else {
            return nil
        }

        let network = NetworkModel(
            networkId: tokenItem.blockchain.networkId,
            contractAddress: contractAddress,
            decimalCount: tokenItem.decimalCount
        )

        return ExpressAddTokenInputData(
            coinId: coinId,
            coinName: tokenItem.name,
            coinSymbol: tokenItem.currencySymbol,
            networks: [network],
            userHasSearchedDuringThisSession: false
        )
    }
}

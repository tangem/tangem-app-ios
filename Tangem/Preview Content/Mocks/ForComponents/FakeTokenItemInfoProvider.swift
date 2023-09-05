//
//  FakeTokenItemInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class FakeTokenItemInfoProvider: ObservableObject {
    let pendingTransactionNotifier = PassthroughSubject<(WalletModelId, Bool), Never>()

    private var amountsIndex = 0
    private var previouslyTappedModelId: Int?
    private var bag = Set<AnyCancellable>()

    var hasPendingTransactions: Bool { false }

    private(set) var viewModels: [TokenItemViewModel] = []

    private var walletModels: [WalletModel] = []

    init(walletManagers: [FakeWalletManager]) {
        walletModels = walletManagers.flatMap { $0.walletModels }
        viewModels = walletModels.map { walletModel in
            TokenItemViewModel(
                id: walletModel.id,
                tokenIcon: makeTokenIconInfo(for: walletModel),
                isTestnetToken: walletModel.blockchainNetwork.blockchain.isTestnet,
                infoProvider: DefaultTokenItemInfoProvider(walletModel: walletModel),
                priceChangeProvider: self,
                tokenTapped: modelTapped(with:)
            )
        }
    }

    func modelTapped(with id: Int) {
        guard let tappedWalletManager = walletModels.first(where: { $0.id == id }) else {
            return
        }
        print("Tapped wallet model: \(tappedWalletManager)")
        var updateSubscription: AnyCancellable?
        updateSubscription = tappedWalletManager.update(silent: true)
            .sink { newState in
                print("Receive new state \(newState) for \(tappedWalletManager)")
                withExtendedLifetime(updateSubscription) {}
            }
    }

    private func makeTokenIconInfo(for walletModel: WalletModel) -> TokenIconInfo {
        return TokenIconInfoBuilder()
            .build(
                for: walletModel.tokenItem.amountType,
                in: walletModel.blockchainNetwork.blockchain
            )
    }
}

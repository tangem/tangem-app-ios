//
//  UserWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol UserWalletModelOutput: AnyObject {
    func userWalletModelRequestUpdate(walletsBalanceState: CardViewModel.WalletsBalanceState)
}

class CommonUserWalletModel {
    /// Public until managers factory
    let userTokenListManager: UserTokenListManager
    private(set) var userWallet: UserWallet
    private let walletListManager: WalletListManager

    private weak var output: UserWalletModelOutput?
    private var reloadAllWalletModelsBag: AnyCancellable?

    init(config: UserWalletConfig, userWallet: UserWallet, output: UserWalletModelOutput?) {
        self.output = output
        self.userWallet = userWallet

        userTokenListManager = CommonUserTokenListManager(config: config, userWalletId: userWallet.userWalletId)
        walletListManager = CommonWalletListManager(
            config: config,
            userTokenListManager: userTokenListManager
        )
    }
}

// MARK: - UserWalletModel

extension CommonUserWalletModel: UserWalletModel {
    func setUserWallet(_ userWallet: UserWallet) {
        self.userWallet = userWallet
    }

    func updateUserWalletModel(with config: UserWalletConfig) {
        print("🔄 Updating UserWalletModel with new config")
        walletListManager.update(config: config)
    }

    func getWalletModels() -> [WalletModel] {
        walletListManager.getWalletModels()
    }

    func subscribeToWalletModels() -> AnyPublisher<[WalletModel], Never> {
        walletListManager.subscribeToWalletModels()
    }

    func getEntriesWithoutDerivation() -> [StorageEntry] {
        walletListManager.getEntriesWithoutDerivation()
    }

    func subscribeToEntriesWithoutDerivation() -> AnyPublisher<[StorageEntry], Never> {
        walletListManager.subscribeToEntriesWithoutDerivation()
    }

    func clearRepository(result: @escaping (Result<UserTokenList, Error>) -> Void) {
        userTokenListManager.clearRepository(result: result)
    }

    func updateAndReloadWalletModels(showProgressLoading: Bool, result: @escaping (Result<Void, Error>) -> Void) {
        if showProgressLoading {
            output?.userWalletModelRequestUpdate(walletsBalanceState: .inProgress)
        }

        // Update walletModel list for current storage state
        walletListManager.updateWalletModels()

        reloadAllWalletModelsBag = walletListManager
            .reloadWalletModels()
            .receive(on: RunLoop.main)
            .receiveCompletion { [weak self] completion in
                self?.output?.userWalletModelRequestUpdate(walletsBalanceState: .loaded)

                switch completion {
                case .finished:
                    result(.success(()))
                case let .failure(error):
                    result(.failure(error))
                }
            }
    }

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        walletListManager.canManage(amountType: amountType, blockchainNetwork: blockchainNetwork)
    }

    func update(entries: [StorageEntry], result: @escaping (Result<UserTokenList, Error>) -> Void) {
        userTokenListManager.update(.rewrite(entries), result: result)

        updateAndReloadWalletModels(showProgressLoading: true)
    }

    func append(entries: [StorageEntry], result: @escaping (Result<UserTokenList, Error>) -> Void) {
        userTokenListManager.update(.append(entries), result: result)

        updateAndReloadWalletModels(showProgressLoading: true)
    }

    func remove(item: RemoveItem, result: @escaping (Result<UserTokenList, Error>) -> Void) {
        guard walletListManager.canRemove(amountType: item.amount, blockchainNetwork: item.blockchainNetwork) else {
            assertionFailure("\(item.blockchainNetwork.blockchain) can't be remove")
            return
        }

        switch item.amount {
        case .coin:
            removeBlockchain(item.blockchainNetwork, result: result)
        case let .token(token):
            removeToken(token, in: item.blockchainNetwork, result: result)
        case .reserve: break
        }
    }
}

// MARK: - Wallet models Operations

private extension CommonUserWalletModel {
    func removeBlockchain(_ network: BlockchainNetwork, result: @escaping (Result<UserTokenList, Error>) -> Void) {
        userTokenListManager.update(.removeBlockchain(network), result: result)
        walletListManager.updateWalletModels()
    }

    func removeToken(_ token: Token, in network: BlockchainNetwork, result: @escaping (Result<UserTokenList, Error>) -> Void) {
        userTokenListManager.update(.removeToken(token, in: network), result: result)
        walletListManager.removeToken(token, blockchainNetwork: network)
        walletListManager.updateWalletModels()
    }
}

extension CommonUserWalletModel {
    struct RemoveItem {
        let amount: Amount.AmountType
        let blockchainNetwork: BlockchainNetwork
    }
}

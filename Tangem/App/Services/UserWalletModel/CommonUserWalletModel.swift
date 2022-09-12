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
    let walletListManager: WalletListManager

    private weak var output: UserWalletModelOutput?
    private var reloadAllWalletModelsBag: AnyCancellable?

    init(config: UserWalletConfig, userWalletId: Data, output: UserWalletModelOutput?) {
        self.output = output

        userTokenListManager = CommonUserTokenListManager(config: config, userWalletId: userWalletId)
        walletListManager = CommonWalletListManager(
            config: config,
            userTokenListManager: userTokenListManager
        )
    }
}

// MARK: - UserWalletModel

extension CommonUserWalletModel: UserWalletModel {
    func updateUserWalletModel(with config: UserWalletConfig) {
        print("🟩 Updating UserWalletModel with new config")
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

    func updateAllWalletModelsWithCallUpdateInWalletModel(showProgressLoading: Bool, result: @escaping (Result<Void, Error>) -> Void) {
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

    func update(entries: [StorageEntry], result: @escaping (Result<UserTokenList, Error>) -> Void) {
        userTokenListManager.update(.rewrite(entries), result: result)
    }

    func append(entries: [StorageEntry], result: @escaping (Result<UserTokenList, Error>) -> Void) {
        userTokenListManager.update(.append(entries), result: result)
    }

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        walletListManager.canManage(amountType: amountType, blockchainNetwork: blockchainNetwork)
    }

    func remove(item: RemoveItem, completion: @escaping (Result<UserTokenList, Error>) -> Void) {
        guard walletListManager.canRemove(amountType: item.amount, blockchainNetwork: item.blockchainNetwork) else {
            assertionFailure("\(item.blockchainNetwork.blockchain) can't be remove")
            return
        }

        switch item.amount {
        case .coin:
            removeBlockchain(item.blockchainNetwork, completion: completion)
        case let .token(token):
            removeToken(token, in: item.blockchainNetwork, completion: completion)
        case .reserve: break
        }
    }
}

// MARK: - Wallet models Operations

private extension CommonUserWalletModel {
    func removeBlockchain(_ network: BlockchainNetwork, completion: @escaping (Result<UserTokenList, Error>) -> Void) {
        userTokenListManager.update(.removeBlockchain(network)) { result in
            switch result {
            case let .success(list):
                print("Remove blockchainNetwork \(network.blockchain.displayName) success")
                completion(.success(list))
            case let .failure(error):
                print("Remove blockchainNetwork \(network.blockchain.displayName) error \(error)")
                completion(.failure(error))
            }
        }

        walletListManager.updateWalletModels()
    }

    func removeToken(_ token: Token, in network: BlockchainNetwork, completion: @escaping (Result<UserTokenList, Error>) -> Void) {
        userTokenListManager.update(.removeToken(token, in: network)) { result in
            switch result {
            case let .success(list):
                print("Remove token \(token.name) success")
                completion(.success(list))
            case let .failure(error):
                print("Remove token \(token.name) error \(error)")
                completion(.failure(error))
            }
        }

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

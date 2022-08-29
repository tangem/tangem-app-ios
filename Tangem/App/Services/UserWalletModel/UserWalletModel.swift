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

class UserWalletModel {
    private weak var output: UserWalletModelOutput?

    /// Public until managers factory
    let userTokenListManager: UserTokenListManager
    let walletListManager: WalletListManager

    private var reloadAllWalletModelsBag: AnyCancellable?

    init(config: UserWalletConfig, userWalletId: String, output: UserWalletModelOutput?) {
        self.output = output

        userTokenListManager = CommonUserTokenListManager(config: config, userWalletId: userWalletId)
        walletListManager = CommonWalletListManager(
            config: config,
            userTokenListManager: userTokenListManager
        )
    }
}

// MARK: - UserWalletModelProtocol

extension UserWalletModel: UserWalletModelProtocol {
    func updateUserWalletModel(with config: UserWalletConfig) {
        print("🟩 Updating UserWalletModel with new config")
        walletListManager.update(config: config)
    }

    func getWalletModels() -> [WalletModel] {
        walletListManager.getWalletModels()
    }

    func subscribeWalletModels() -> AnyPublisher<[WalletModel], Never> {
        walletListManager.subscribeWalletModels()
    }

    func getNonDerivationEntries() -> [StorageEntry] {
        walletListManager.getNonDerivationEntries()
    }

    func subscribeNonDerivationEntries() -> AnyPublisher<[StorageEntry], Never> {
        walletListManager.subscribeNonDerivationEntries()
    }

    func clearRepository(result: @escaping (Result<UserTokenList, Error>) -> Void) {
        userTokenListManager.clearRepository(result: result)
    }

    func updateAllWalletModelsWithCallUpdateInWalletModel(showProgressLoading: Bool) {
        if showProgressLoading {
            output?.userWalletModelRequestUpdate(walletsBalanceState: .inProgress)
        }

        // Update walletModel list for current storage state
        walletListManager.updateWalletModels()

        reloadAllWalletModelsBag = walletListManager
            .reloadAllWalletModels()
            .receive(on: RunLoop.main)
            .receiveCompletion { [weak self] _ in
                if showProgressLoading {
                    self?.output?.userWalletModelRequestUpdate(walletsBalanceState: .loaded)
                }
            }
    }

    func add(entries: [StorageEntry], completion: @escaping (Result<UserTokenList, Error>) -> Void) {
        /// Sync update entries in repository and async update entries on server
        userTokenListManager.append(entries: entries, result: completion)

        updateAllWalletModelsWithCallUpdateInWalletModel(showProgressLoading: true)
    }

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        walletListManager.canManage(amountType: amountType, blockchainNetwork: blockchainNetwork)
    }

    func remove(items: [RemoveItem], completion: @escaping (Result<Void, Error>) -> Void) {
        let workGroup = DispatchGroup()
        var error: Error?

        items.forEach { item in
            workGroup.enter()
            remove(item: item) { result in
                workGroup.leave()

                if case let .failure(err) = result {
                    error = err
                }
            }
        }

        workGroup.notify(queue: .main) {
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

// MARK: - Wallet models Operations

private extension UserWalletModel {
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

    func removeBlockchain(_ blockchainNetwork: BlockchainNetwork, completion: @escaping (Result<UserTokenList, Error>) -> Void) {
        userTokenListManager.remove(blockchain: blockchainNetwork) { result in
            switch result {
            case let .success(list):
                print("Remove blockchainNetwork \(blockchainNetwork.blockchain.displayName) success")
                completion(.success(list))
            case let .failure(error):
                print("Remove blockchainNetwork \(blockchainNetwork.blockchain.displayName) error \(error)")
                completion(.failure(error))
            }
        }

        walletListManager.updateWalletModels()
    }

    func removeToken(_ token: Token, in blockchainNetwork: BlockchainNetwork, completion: @escaping (Result<UserTokenList, Error>) -> Void) {
        userTokenListManager.remove(tokens: [token], in: blockchainNetwork) { result in
            switch result {
            case let .success(list):
                print("Remove token \(token.name) success")
                completion(.success(list))
            case let .failure(error):
                print("Remove token \(token.name) error \(error)")
                completion(.failure(error))
            }
        }

        walletListManager.removeToken(token, blockchainNetwork: blockchainNetwork)
        walletListManager.updateWalletModels()
    }
}

extension UserWalletModel {
    struct RemoveItem {
        let amount: Amount.AmountType
        let blockchainNetwork: BlockchainNetwork
    }
}

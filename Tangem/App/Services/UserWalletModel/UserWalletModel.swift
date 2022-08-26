//
//  UserWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSdk
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
        print("🟩 Updating UserWalletModel with new config \(config)")

        walletListManager.update(config: config)
        userTokenListManager.update(config: config)

//        updateAllWalletModelsWithCallUpdateInWalletModel(showProgressLoading: true)
    }

    func getWalletModels() -> [WalletModel] {
        walletListManager.getWalletModels()
    }

    func subscribeWalletModels() -> AnyPublisher<[WalletModel], Never> {
        walletListManager.subscribeWalletModels()
    }

    func clearRepository(result: @escaping (Result<UserTokenList, Error>) -> Void) {
        userTokenListManager.clearRepository(result: result)
    }

    // MARK: - Proxy from CardViewModel

    func add(entries: [StorageEntry], completion: @escaping (Result<UserTokenList, Error>) -> Void) {
        append(entries: entries) { [weak self] appendingCompletion in
            switch appendingCompletion {
            case .success(let list):
                self?.updateAllWalletModelsWithCallUpdateInWalletModel(showProgressLoading: true)
                completion(.success(list))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        walletListManager.canManage(amountType: amountType, blockchainNetwork: blockchainNetwork)
    }

    func remove(items: [(Amount.AmountType, BlockchainNetwork)]) {
        items.forEach {
            remove(amountType: $0.0, blockchainNetwork: $0.1)
        }
    }

    func remove(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) {
        guard walletListManager.canRemove(amountType: amountType, blockchainNetwork: blockchainNetwork) else {
            assertionFailure("\(blockchainNetwork.blockchain) can't be remove")
            return
        }

        switch amountType {
        case .coin:
            removeBlockchain(blockchainNetwork)
        case let .token(token):
            removeToken(token, blockchainNetwork: blockchainNetwork)
        case .reserve: break
        }
    }

    /// What this method do?
    /// 1. `tryMigrateTokens` once, work with boolean switcher
    /// 2. Call `update` for every `walletModels`
    /// 3. Update the `walletsBalanceState` to `.inProgress` if needed and `.loaded` when the update completed
    func updateAllWalletModelsWithCallUpdateInWalletModel(showProgressLoading: Bool) {
        if showProgressLoading {
            output?.userWalletModelRequestUpdate(walletsBalanceState: .inProgress)
        }

        // Create new walletModel if needed
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
}

// MARK: - Wallet models Operations

private extension UserWalletModel {
    func append(entries: [StorageEntry], completion: @escaping (Result<UserTokenList, Error>) -> Void) {
        userTokenListManager.append(entries: entries, result: completion)
    }

    private func removeBlockchain(_ blockchainNetwork: BlockchainNetwork) {
        userTokenListManager.remove(blockchain: blockchainNetwork) { [weak self] result in
            switch result {
            case .success:
                self?.walletListManager.updateWalletModels()
            case let .failure(error):
                print("Remove blockchainNetwork error \(error)")
            }
        }
    }

    private func removeToken(_ token: BlockchainSdk.Token, blockchainNetwork: BlockchainNetwork) {
        userTokenListManager.remove(tokens: [token], in: blockchainNetwork) { [weak self] result in
            switch result {
            case .success:
                self?.walletListManager.removeToken(token, blockchainNetwork: blockchainNetwork)
                self?.walletListManager.updateWalletModels()
            //                _ = walletModel.removeToken(token)
            //                self?.updateState(shouldUpdate: false)
            case let .failure(error):
                print("Remove token error \(error)")
            }
        }
    }
}

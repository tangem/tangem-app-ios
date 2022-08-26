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
    func userWalletModelDidUpdate(card: Card)
}

protocol UserWalletModelProtocol {
    func loadAndSaveUserTokenList() -> AnyPublisher<UserTokenList, Error>
    func subscribeWalletModels() -> AnyPublisher<[WalletModel], Never>

    func updateModel(with card: Card)
    func getWalletModels() -> [WalletModel]

    func add(entries: [StorageEntry], completion: @escaping (Result<Void, Error>) -> Void)
    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool
    func remove(items: [(Amount.AmountType, BlockchainNetwork)])
    func clearRepository(result: @escaping (Result<Void, Error>) -> Void)

    // Proxy from CardViewModel
    func getUserWalletId() -> String
    func appendDefaultBlockchains()
    func updateAllWalletModelsWithCallUpdateInWalletModel(showProgressLoading: Bool)
}

class UserWalletModel {
    private var cardInfo: CardInfo
    private var config: UserWalletConfig
    private weak var output: UserWalletModelOutput?

    /// This managers will be recreated in `updateModel()` method
    /// Public until managers factory
    var userTokenListManager: UserTokenListManager
    var walletListManager: WalletListManager

    private var userWalletId: String { cardInfo.card.userWalletId }
    private var reloadAllWalletModelsBag: AnyCancellable?

    init(cardInfo: CardInfo) {
        self.cardInfo = cardInfo
        self.config = UserWalletConfigFactory(cardInfo).makeConfig()

        userTokenListManager = CommonUserTokenListManager(config: config, cardInfo: cardInfo)
        walletListManager = CommonWalletListManager(
            config: config,
            cardInfo: cardInfo,
            userTokenListManager: userTokenListManager
        )
    }
}

// MARK: - UserWalletModelProtocol

extension UserWalletModel: UserWalletModelProtocol {
    func updateModel(with card: Card) {
        print("🟩 Updating UserWalletModel with new Card \(card.cardId)")

        output?.userWalletModelDidUpdate(card: card)
        cardInfo.card = card // [REDACTED_TODO_COMMENT]
        config = UserWalletConfigFactory(cardInfo).makeConfig()

        userTokenListManager = CommonUserTokenListManager(config: config, cardInfo: cardInfo)
        walletListManager = CommonWalletListManager(
            config: config,
            cardInfo: cardInfo,
            userTokenListManager: userTokenListManager
        )

        updateAllWalletModelsWithCallUpdateInWalletModel(showProgressLoading: true)
    }

    func loadAndSaveUserTokenList() -> AnyPublisher<UserTokenList, Error> {
        userTokenListManager.loadAndSaveUserTokenList()
    }

    func getWalletModels() -> [WalletModel] {
        walletListManager.getWalletModels()
    }

    func subscribeWalletModels() -> AnyPublisher<[WalletModel], Never> {
        walletListManager.subscribeWalletModels()
    }

    func clearRepository(result: @escaping (Result<Void, Error>) -> Void) {
        userTokenListManager.clearRepository(result: result)
    }

    // MARK: - Proxy from CardViewModel

    func getUserWalletId() -> String {
        userWalletId
    }

    func add(entries: [StorageEntry], completion: @escaping (Result<Void, Error>) -> Void) {
        append(entries: entries, completion: completion)
    }

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        return walletListManager.canManage(amountType: amountType, blockchainNetwork: blockchainNetwork)
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

    func appendDefaultBlockchains() {
        userTokenListManager.append(entries: config.defaultBlockchains) { [weak self] result in
            switch result {
            case let .success(card):
                if let card = card {
                    self?.updateModel(with: card)
                }
            case let .failure(error):
                print("Append defaultBlockchains error: \(error)")
            }
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
    func append(entries: [StorageEntry], completion: @escaping (Result<Void, Error>) -> Void) {
        userTokenListManager.append(entries: entries) { [weak self] result in
            switch result {
            case let .success(card):
                if let card = card {
                    self?.updateModel(with: card)
                } else {
                    self?.walletListManager.updateWalletModels()
                }
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
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

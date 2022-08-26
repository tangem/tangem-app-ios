//
//  DeriveManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSdk

struct DeriveManager {
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding

    private let config: UserWalletConfig
    private let cardInfo: CardInfo
    private let tokenItemsRepository: TokenItemsRepository

    init(config: UserWalletConfig, cardInfo: CardInfo, userWalletId: String) {
        self.config = config
        self.cardInfo = cardInfo

        tokenItemsRepository = CommonTokenItemsRepository(key: userWalletId)
    }

    func deriveIfNeeded(entries: [StorageEntry], completion: @escaping (Result<Card?, Error>) -> Void) {
        guard config.hasFeature(.hdWallets) else {
            completion(.success(nil))
            return
        }

        var shouldDerive: Bool = false

        for entry in entries {
            if let path = entry.blockchainNetwork.derivationPath,
               let wallet = cardInfo.card.wallets.first(where: { $0.curve == entry.blockchainNetwork.blockchain.curve }),
               !wallet.derivedKeys.keys.contains(path) {
                shouldDerive = true
                break
            }
        }

        guard shouldDerive else {
            completion(.success(nil))
            return
        }

        deriveKeys(completion: completion)
    }

    private func deriveKeys(completion: @escaping (Result<Card?, Error>) -> Void) {
        let card = cardInfo.card
        let entries = tokenItemsRepository.getItems()
        var derivations: [EllipticCurve: [DerivationPath]] = [:]

        for entry in entries {
            if let path = entry.blockchainNetwork.derivationPath {
                derivations[entry.blockchainNetwork.blockchain.curve, default: []].append(path)
            }
        }

        tangemSdkProvider.sdk.config.defaultDerivationPaths = derivations
        tangemSdkProvider.sdk.startSession(with: ScanTask(), cardId: card.cardId) { result in
            switch result {
            case .success(let card):
                completion(.success(card))
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .purgeWallet, card: card)
                completion(.failure(error))
            }
        }
    }
}

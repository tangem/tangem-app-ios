//
//  DerivationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSdk

struct DerivationManager {
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding

    private let config: UserWalletConfig
    private let cardInfo: CardInfo

    init(config: UserWalletConfig, cardInfo: CardInfo) {
        self.config = config
        self.cardInfo = cardInfo
    }

    func deriveIfNeeded(entries: [StorageEntry], completion: @escaping (Result<Card?, TangemSdkError>) -> Void) {
        guard config.hasFeature(.hdWallets) else {
            completion(.success(nil))
            return
        }

        let nonDeriveEntries = entries.compactMap { entry -> StorageEntry? in
            guard let path = entry.blockchainNetwork.derivationPath,
                  let wallet = cardInfo.card.wallets.first(where: { $0.curve == entry.blockchainNetwork.blockchain.curve }),
                  !wallet.derivedKeys.keys.contains(path) else {
                return nil
            }

            return entry
        }

        guard !nonDeriveEntries.isEmpty else {
            completion(.success(nil))
            return
        }

        deriveKeys(entries: nonDeriveEntries, completion: completion)
    }

    private func deriveKeys(entries: [StorageEntry], completion: @escaping (Result<Card?, TangemSdkError>) -> Void) {
        let card = cardInfo.card
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

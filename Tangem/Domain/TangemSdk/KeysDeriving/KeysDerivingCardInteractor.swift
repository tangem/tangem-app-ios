//
//  KeysDerivingCardInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class KeysDerivingCardInteractor {
    private let tangemSdk: TangemSdk
    private let filter: SessionFilter

    init(with cardInfo: CardInfo) {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)
        tangemSdk = config.makeTangemSdk()
        filter = config.cardSessionFilter
    }
}

// MARK: - KeysDeriving

extension KeysDerivingCardInteractor: KeysDeriving {
    func deriveKeys(derivations: [Data: [DerivationPath]], completion: @escaping (Result<DerivationResult, Error>) -> Void) {
        let task = DeriveMultipleWalletPublicKeysTask(derivations)

        tangemSdk.startSession(
            with: task,
            filter: filter
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                AppLogger.error(error: error)
                Analytics.error(error: error, params: [.action: .deriveKeys])

                completion(.failure(error))
            }

            withExtendedLifetime(task) {}
        }
    }
}

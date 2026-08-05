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
    private let filter: SessionFilter
    private let sdkFactory: TangemSdkFactory

    init(with cardInfo: CardInfo) {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)
        filter = config.cardSessionFilter
        sdkFactory = config
    }
}

// MARK: - KeysDeriving

extension KeysDerivingCardInteractor: KeysDeriving {
    var requiresCard: Bool { true }

    func deriveKeys(derivations: [Data: [DerivationPath]], completion: @escaping (Result<DerivationResult, Error>) -> Void) {
        let task = DeriveMultipleWalletPublicKeysTask(derivations)
        let tangemSdk = sdkFactory.makeTangemSdk()
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
            withExtendedLifetime(tangemSdk) {}
        }
    }
}

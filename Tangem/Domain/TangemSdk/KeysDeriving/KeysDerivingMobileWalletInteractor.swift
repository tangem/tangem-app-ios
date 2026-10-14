//
//  KeysDerivingMobileWalletInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletSdk
import TangemSdk
import TangemFoundation

class KeysDerivingMobileWalletInteractor {
    let userWalletId: UserWalletId
    let userWalletConfig: UserWalletConfig

    init(userWalletId: UserWalletId, userWalletConfig: UserWalletConfig) {
        self.userWalletId = userWalletId
        self.userWalletConfig = userWalletConfig
    }
}

// MARK: - KeysDeriving

extension KeysDerivingMobileWalletInteractor: KeysDeriving {
    var requiresCard: Bool { false }

    func deriveKeys(
        derivations: [Data: [DerivationPath]],
        completion: @escaping (Result<DerivationResult, Error>) -> Void
    ) {
        let sdk = CommonMobileWalletSdk()

        runTask(in: self) { interactor in
            do {
                let context = try await MobileAuthUtil(
                    userWalletId: interactor.userWalletId,
                    config: interactor.userWalletConfig,
                    biometricsProvider: CommonUserWalletBiometricsProvider()
                )
                .unlockedContext()
                let derived = try sdk.deriveKeys(context: context, derivationPaths: derivations)

                let mapped: DerivationResult = derived.reduce(into: [:]) { partialResult, keyInfo in
                    partialResult[keyInfo.key] = .init(keys: keyInfo.value.derivedKeys)
                }

                completion(.success(mapped))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

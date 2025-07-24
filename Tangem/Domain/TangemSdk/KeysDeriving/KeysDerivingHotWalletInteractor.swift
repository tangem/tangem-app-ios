//
//  KeysDerivingHotWalletInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemHotSdk
import TangemSdk

class KeysDerivingHotWalletInteractor {
    let hotWallet: HotWallet

    init(hotWallet: HotWallet?) { // [REDACTED_TODO_COMMENT]
        self.hotWallet = hotWallet!
    }
}

// MARK: - KeysDeriving

extension KeysDerivingHotWalletInteractor: KeysDeriving {
    func deriveKeys(
        derivations: [Data: [DerivationPath]],
        completion: @escaping (Result<DerivationResult, Error>) -> Void
    ) {
        let sdk = CommonHotSdk(
            secureStorage: SecureStorage(),
            biometricsStorage: BiometricsStorage(),
            secureEnclaveService: SecureEnclaveService(config: .default)
        )

        let result: Result<DerivationResult, Error> = Result {
            // [REDACTED_TODO_COMMENT]
            let updatedWallet = try sdk.deriveKeys(wallet: hotWallet, auth: nil, derivationPaths: derivations)

            return updatedWallet.wallets.reduce(into: [:]) { partialResult, keyInfo in
                partialResult[keyInfo.publicKey] = .init(keys: keyInfo.derivedKeys)
            }
        }

        completion(result)
    }
}

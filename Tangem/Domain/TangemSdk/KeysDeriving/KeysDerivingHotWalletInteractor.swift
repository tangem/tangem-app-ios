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
import TangemFoundation

class KeysDerivingHotWalletInteractor {
    let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }
}

// MARK: - KeysDeriving

extension KeysDerivingHotWalletInteractor: KeysDeriving {
    func deriveKeys(
        derivations: [Data: [DerivationPath]],
        completion: @escaping (Result<DerivationResult, Error>) -> Void
    ) {
        let sdk = CommonHotSdk()

        let result: Result<DerivationResult, Error> = Result {
            // [REDACTED_TODO_COMMENT]
            let derived = try sdk.deriveKeys(walletID: userWalletId, auth: .none, derivationPaths: derivations)

            return derived.reduce(into: [:]) { partialResult, keyInfo in
                partialResult[keyInfo.key] = .init(keys: keyInfo.value.derivedKeys)
            }
        }

        completion(result)
    }
}

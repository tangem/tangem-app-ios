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
    let entropy: Data
    let passphrase: String

    init(entropy: Data, passphrase: String) {
        self.entropy = entropy
        self.passphrase = passphrase
    }
}

// MARK: - KeysDeriving

extension KeysDerivingHotWalletInteractor: KeysDeriving {
    func deriveKeys(
        derivations: [Data: [DerivationPath]],
        completion: @escaping (Result<DerivationResult, Error>) -> Void
    ) {
        let result: Result<DerivationResult, Error> = Result {
            try derivations.reduce(into: [:]) { result, derivation in
                let derivedKeys = try deriveKeys(
                    derivationPaths: derivation.value,
                    masterKey: derivation.key
                )
                result[derivation.key] = derivedKeys
            }
        }

        completion(result)
    }

    private func deriveKeys(
        derivationPaths: [DerivationPath],
        masterKey: Data
    ) throws -> DerivedKeys {
        let keys: [DerivationPath: ExtendedPublicKey] = try derivationPaths.reduce(into: [:]) { partResult, path in
            let derivedKey = try DerivationUtil.deriveKeys(
                entropy: entropy,
                passphrase: passphrase,
                derivationPath: path.rawPath,
                masterKey: masterKey
            )
            partResult[path] = derivedKey
        }

        return DerivedKeys(keys: keys)
    }
}

//
//  KeysDeriving.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

typealias DerivationResult = DeriveMultipleWalletPublicKeysTask.Response

protocol KeysDeriving: AnyObject {
    func deriveKeys(derivations: [Data: [DerivationPath]], completion: @escaping (Result<DerivationResult, Error>) -> Void)
}

extension KeysDeriving {
    func deriveKeys(derivations: [Data: [DerivationPath]]) async throws -> DerivationResult {
        return try await withCheckedThrowingContinuation { continuation in
            deriveKeys(derivations: derivations, completion: { result in
                continuation.resume(with: result)
            })
        }
    }
}

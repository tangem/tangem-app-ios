//
//  KeysDerivingMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class KeysDerivingMock: KeysDeriving {
    var isKeysDerivedByCard: Bool { true }

    func deriveKeys(derivations: [Data: [DerivationPath]], completion: @escaping (Result<DerivationResult, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(.success([:]))
        }
    }
}

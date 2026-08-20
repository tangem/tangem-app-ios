//
//  KeysRepositoryTestsMock.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
@testable import Tangem

final class KeysRepositoryTestsMock: KeysRepository {
    private let storedKeys: CurrentValueSubject<[KeyInfo], Never>
    private let persists: Bool

    init(keys: [KeyInfo], persists: Bool = true) {
        storedKeys = .init(keys)
        self.persists = persists
    }

    var keys: [KeyInfo] { storedKeys.value }

    var keysPublisher: AnyPublisher<[KeyInfo], Never> {
        storedKeys.eraseToAnyPublisher()
    }

    func update(derivations: DerivationResult) {
        guard persists else {
            return
        }

        storedKeys.value = storedKeys.value.map { key in
            guard let publicKey = key.publicKey, let derived = derivations[publicKey] else {
                return key
            }

            var updated = key
            derived.keys.forEach { updated.derivedKeys[$0.key] = $0.value }
            return updated
        }
    }

    func update(keys: WalletKeys) {
        storedKeys.value = keys.asKeyInfo
    }
}

//
//  CryptoAccountDerivationIdentity.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// A derivation index paired with the account kind. Each account kind runs its own derivation counter,
/// so a bare `derivationIndex` does not identify an account within a wallet.
struct CryptoAccountDerivationIdentity: Hashable {
    let derivationIndex: Int
    let type: AccountType

    init(derivationIndex: Int, type: AccountType) {
        self.derivationIndex = derivationIndex
        self.type = type
    }
}

// MARK: - AccountModelPersistentIdentifierConvertible

extension CryptoAccountDerivationIdentity: AccountModelPersistentIdentifierConvertible {
    /// - Warning: Persisted, by the storage keys and identifier strings built from it. A crypto account renders as the
    /// bare index it has always rendered as, so everything keyed that way before the kinds existed stays found.
    func toPersistentIdentifier() -> AnyHashable {
        switch type {
        case .crypto:
            return derivationIndex.toAnyHashable()
        case .joint:
            return "\(type.rawValue)\(derivationIndex)".toAnyHashable()
        }
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CryptoAccountDerivationIdentity: CustomStringConvertible {
    var description: String {
        "\(derivationIndex)/\(type.rawValue)"
    }
}

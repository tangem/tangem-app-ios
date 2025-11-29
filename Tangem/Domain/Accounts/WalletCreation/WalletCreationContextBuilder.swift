//
//  WalletCreationContextBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import AnyCodable

/// Builder for creating an opaque wallet creation context used in the Tangem API.
final class WalletCreationContextBuilder {
    private var storage: [String: AnyEncodable]

    init(
        storage: [String: AnyEncodable]
    ) {
        self.storage = storage
    }

    func enrich(withName name: some Encodable) -> Self {
        storage["name"] = AnyEncodable(name)
        return self
    }

    func enrich(withIdentifier identifier: some Encodable) -> Self {
        storage["id"] = AnyEncodable(identifier)
        return self
    }

    func build() -> some Encodable {
        return storage
    }
}

// MARK: - ExpressibleByDictionaryLiteral protocol conformance

extension WalletCreationContextBuilder: ExpressibleByDictionaryLiteral {
    convenience init(dictionaryLiteral elements: (String, AnyEncodable)...) {
        self.init(storage: Dictionary(uniqueKeysWithValues: elements))
    }
}

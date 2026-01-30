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
    @Injected(\.referralService) private var referralService: ReferralService

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

    func enrichReferral() -> Self {
        if let referral = referralService.refcode {
            storage["ref"] = AnyEncodable(referral)

            if let campaign = referralService.campaign {
                storage["campaign"] = AnyEncodable(campaign)
            }
        }

        return self
    }

    func build() -> some Encodable {
        return storage
    }

    @available(iOS, deprecated: 100000.0, message: "Will be removed in the future ([REDACTED_INFO])")
    func buildRaw() -> [String: String] {
        return storage.mapValues { $0.value as! String }
    }
}

// MARK: - ExpressibleByDictionaryLiteral protocol conformance

extension WalletCreationContextBuilder: ExpressibleByDictionaryLiteral {
    convenience init(dictionaryLiteral elements: (String, AnyEncodable)...) {
        self.init(storage: Dictionary(uniqueKeysWithValues: elements))
    }
}

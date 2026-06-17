//
//  AddressBookNetworkID.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Network identifier of an address entry. Equals `Blockchain.networkId` — the `coin.network_id`
/// foreign key the backend and other clients use. A single typed wrapper keeps network identity
/// consistent across validation, dedup and the signed tuple.
struct AddressBookNetworkID: Hashable {
    let rawValue: String

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

extension AddressBookNetworkID: Codable {
    init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

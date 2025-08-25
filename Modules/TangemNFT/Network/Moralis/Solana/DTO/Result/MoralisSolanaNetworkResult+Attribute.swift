//
//  MoralisSolanaNetworkResult+Attribute.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import AnyCodable

extension MoralisSolanaNetworkResult {
    struct Attribute: Decodable {
        let traitType: String?
        let value: AnyDecodable?
    }
}

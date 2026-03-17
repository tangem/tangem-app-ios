//
//  MockExpressExchangeDataDecoder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if DEBUG

import Foundation
import TangemExpress

/// Decoder that skips signature verification for WireMock-based UI tests
struct MockExpressExchangeDataDecoder: ExpressExchangeDataDecoder {
    func decode<T: Decodable>(txDetailsJson: String, signature: String) throws -> T {
        let txDetailsData = Data(txDetailsJson.utf8)
        return try JSONDecoder().decode(T.self, from: txDetailsData)
    }
}

#endif // DEBUG

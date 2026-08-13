//
//  JSONDecoder+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

extension JSONDecoder {
    static var withSnakeCaseStrategy: JSONDecoder {
        let encoder = JSONDecoder()
        encoder.keyDecodingStrategy = .convertFromSnakeCase
        return encoder
    }
}

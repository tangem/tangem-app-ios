//
//  GaslessTransactionsDTO+Envelope.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension GaslessTransactionsDTO.Response {
    struct Envelope<Result: Decodable>: Decodable {
        let result: Result
    }
}

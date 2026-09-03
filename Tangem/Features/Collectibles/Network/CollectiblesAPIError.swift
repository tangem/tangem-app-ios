//
//  CollectiblesAPIError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum CollectiblesAPIError: Error {
    case http(statusCode: Int, body: Data) // error contract TBD
    case decoding(DecodingError)
    case connection(underlying: Error)
}

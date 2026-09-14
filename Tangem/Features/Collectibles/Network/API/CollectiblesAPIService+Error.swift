//
//  CollectiblesAPIService+Error.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya

extension CollectiblesAPIService {
    enum Error: Swift.Error {
        case http(statusCode: Int, body: Data) // error contract TBD
        case decoding(DecodingError)
        case connection(underlying: Swift.Error)
    }
}

extension CollectiblesAPIService.Error {
    init(moyaError: MoyaError) {
        guard let response = moyaError.response else {
            self = .connection(underlying: moyaError.underlyingError ?? moyaError)
            return
        }

        self = .http(statusCode: response.statusCode, body: response.data)
    }
}

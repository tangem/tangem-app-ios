//
//  TangemAPIHeaders.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum TangemAPIHeaders: String {
    case apiKey = "api-key"
    case accept = "Accept"
    case contentType = "Content-Type"
    case eTag = "ETag"
    case ifMatch = "If-Match"
    case ifNoneMatch = "If-None-Match"
    case authorization = "Authorization"
}

enum TangemAPIHHeadersValues {
    static let bearerPrefix: String = "Bearer "
}

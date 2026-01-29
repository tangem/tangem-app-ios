//
//  TangemPayNetworkingConstants.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TangemPayNetworkingConstants {
    enum Header {
        enum Key {
            static let contentType = "Content-Type"
            static let xApiKey = "X-API-KEY"
            static let authorization = "Authorization"
        }

        enum Value {
            static let applicationJson = "application/json"
        }
    }
}

//
//  TangemPayNetworkingConstants.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit

enum TangemPayNetworkingConstants {
    enum Header {
        enum Key {
            static let contentType = "Content-Type"
            static let xApiKey = "X-API-KEY"
            static let authorization = "Authorization"
            static let xDeviceScale = "X-Device-Scale"
            static let acceptLanguage = "Accept-Language"
        }

        enum Value {
            static let applicationJson = "application/json"

            static let deviceScale = String(format: "%.1f", UIScreen.main.scale)
        }
    }
}

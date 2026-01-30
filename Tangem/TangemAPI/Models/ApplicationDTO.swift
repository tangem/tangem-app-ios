//
//  ApplicationDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum ApplicationDTO {
    struct Request: Encodable {
        /// The FCM push notification token (e.g. "fcm-token-123456")
        let pushToken: String?

        // Device Info

        let platform: String
        let device: String
        let systemVersion: String
        let language: String
        let timezone: String
        let version: String
        let appsflyerId: String
    }

    enum Create {
        struct Response: Decodable {
            let uid: String
        }
    }

    enum Update {
        struct Request: Encodable {
            /// The FCM push notification token (e.g. "fcm-token-123456")
            let pushToken: String?
        }
    }

    enum Connect {
        struct Request: Encodable {
            let walletIds: [String]
        }
    }
}

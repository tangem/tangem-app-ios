//
//  UserWalletDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum UserWalletDTO {
    struct Response: Decodable {
        /// Unique identifier of the user wallet
        let id: String
        /// Display name of the wallet
        let name: String?
        /// Flag indicating if notifications are enabled for this wallet
        let notifyStatus: Bool
    }

    enum Update {
        struct Request: Encodable {
            /// Flag to enable/disable notifications for the wallet
            let name: String
        }
    }

    enum Create {
        struct Request: Encodable, Hashable {
            /// Unique identifier for the new wallet
            let id: String
            /// Display name for the new wallet
            let name: String
        }
    }
}

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
    }
}

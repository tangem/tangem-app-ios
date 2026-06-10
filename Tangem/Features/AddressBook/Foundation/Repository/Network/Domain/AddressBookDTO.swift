//
//  RemoteAddressBookInfo.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AddressBookDTO {
    enum Save {
        struct Request: Encodable {
            let version: String
            let walletId: String
            let updatedAt: Date
            let salt: String
            let nonce: String
            let ciphertext: String
            let authTag: String
        }

        struct Response: Decodable {
            // [REDACTED_TODO_COMMENT]
            let ciphertext: String
        }
    }
}

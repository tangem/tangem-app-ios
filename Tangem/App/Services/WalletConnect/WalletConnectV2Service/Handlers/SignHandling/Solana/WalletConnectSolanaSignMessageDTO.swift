//
//  WalletConnectSolanaSignMessageDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum WalletConnectSolanaSignMessageDTO {
    struct Body: Codable {
        /// `Signature` is a signed message from response, encoded as base-58 string
        let signature: String
    }

    struct Response: Codable {
        let message: String
    }
}

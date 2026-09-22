//
//  UnregisterWalletDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// `POST api/authentication/v1/mobile/wallet/unregister`
enum UnregisterWalletDTO {
    struct Request: Encodable {
        let walletId: String
    }
}

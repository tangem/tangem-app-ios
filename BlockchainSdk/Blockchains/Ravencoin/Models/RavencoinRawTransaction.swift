//
//  RavencoinRawTransactionRequestModel.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum RavencoinRawTransaction {
    struct Request: Encodable {
        let rawtx: String
    }

    struct Response: Decodable {
        let txid: String
    }
}

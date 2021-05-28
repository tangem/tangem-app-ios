//
//  EthereumResponse.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct EthereumInfoResponse {
    let balance: Decimal
    let tokenBalances: [Token: Decimal]
}

struct EthereumResponse: Codable {
    let jsonRpc: String
    let id: Int?
    let result: String?
    let error: EthereumError?
    
    private enum CodingKeys: String, CodingKey {
        case jsonRpc = "jsonrpc"
        case id, result, error
    }
}

struct EthereumError: Codable {
    let code: Int?
    let message: String?
    
    var error: Error {
        NSError(domain: message ?? .unknown, code: code ?? -1, userInfo: nil)
    }
}

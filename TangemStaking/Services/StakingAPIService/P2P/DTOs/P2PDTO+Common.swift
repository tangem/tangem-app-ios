//
//  P2PDTO+Common.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension P2PDTO {
    struct GenericResponse<T: Decodable>: Decodable {
        let error: APIError?
        let result: T?
    }

    struct APIError: Decodable {
        let code: Int?
        let message: String?
        let name: String?
        let errors: [ValidationError]?
    }

    struct ValidationError: Decodable {
        let property: String?
        let constraints: [String: String]?
    }

    public struct UnsignedTransaction: Decodable, Hashable {
        let serializeTx: String
        let to: String
        let data: String
        let value: String
        let nonce: Int
        let chainId: Int
        let gasLimit: String
        let maxFeePerGas: String
        let maxPriorityFeePerGas: String
    }
}

//
//  P2PDTO+PrepareUnstakeTransaction.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension P2PDTO {
    enum PrepareUnstakeTransaction {
        struct Request: Encodable {
            let stakerPublicKey: String
            let stakeTransactionHash: String
        }

        typealias Response = GenericResponse<PrepareUnstakeTransactionInfo>

        struct PrepareUnstakeTransactionInfo: Decodable {
            let stakerPublicKey: String
            let stakeTransactionHash: String
            let unstakeTransactionHex: String
            let unstakeFee: Decimal
        }
    }
}

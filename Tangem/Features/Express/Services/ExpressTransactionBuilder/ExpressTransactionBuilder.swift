//
//  ExpressTransactionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

protocol ExpressTransactionBuilder {
    func makeTransaction(data: ExpressTransactionData, fee: Fee) async throws -> BlockchainSdk.Transaction
    func makeApproveTransaction(data: ApproveTransactionData, fee: Fee) async throws -> BlockchainSdk.Transaction
}

//
//  ExpressTransactionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdkLocal
import TangemExpress

protocol ExpressTransactionBuilder {
    func makeTransaction(wallet: WalletModel, data: ExpressTransactionData, fee: Fee) async throws -> BlockchainSdkLocal.Transaction
    func makeApproveTransaction(wallet: WalletModel, data: ApproveTransactionData, fee: Fee) async throws -> BlockchainSdkLocal.Transaction
}

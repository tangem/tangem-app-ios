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
    func makeTransaction(wallet: WalletModel, data: ExpressTransactionData, fee: Fee) async throws -> BlockchainSdk.Transaction
    func makeApproveTransaction(wallet: WalletModel, data: ExpressApproveData, fee: Fee) async throws -> BlockchainSdk.Transaction
}

extension ExpressTransactionBuilder {
    func validateTransaction(wallet: WalletModel, data: ExpressTransactionData, fee: Fee) async throws {
        _ = try await makeTransaction(wallet: wallet, data: data, fee: fee)
    }

    func validateApproveTransaction(wallet: WalletModel, data: ExpressApproveData, fee: Fee) async throws {
        _ = try await makeApproveTransaction(wallet: wallet, data: data, fee: fee)
    }
}

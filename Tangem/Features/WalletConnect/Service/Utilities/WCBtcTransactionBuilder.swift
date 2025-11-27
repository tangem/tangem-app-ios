//
//  WCBtcTransactionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol WCBtcTransactionBuilder {
    func buildTx(
        from transaction: WalletConnectBtcTransaction,
        for walletModel: any WalletModel
    ) async throws -> Transaction
}

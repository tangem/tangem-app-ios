//
//  WCBtcSendTransferDetailsModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct WCBtcSendTransferDetailsModel {
    let data: [WCTransactionDetailsSection]

    init(for method: WalletConnectMethod, source: Data, blockchain: Blockchain) {
        guard let transaction = try? JSONDecoder().decode(WalletConnectBtcTransaction.self, from: source) else {
            data = []
            return
        }

        data = WCRequestDetailsBtcTransactionParser.parse(
            transaction: transaction,
            method: method,
            blockchain: blockchain
        )
    }
}

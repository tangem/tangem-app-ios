//
//  TransactionHistoryAuxDataRepository+Contract.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress

extension TransactionHistoryAuxDataRepository {
    nonisolated func cryptoCurrency(forContract contractAddress: String, blockchain: Blockchain) -> TokenItem? {
        let currency = ExpressCurrency(
            contractAddress: TransactionHistoryAddressNormalizer.normalize(contractAddress, isEvm: blockchain.isEvm),
            network: blockchain.networkId
        )

        return cryptoCurrency(for: currency)
    }
}

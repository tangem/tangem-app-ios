//
//  ExpressTransactionBuilderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk

struct ExpressTransactionBuilderFactory {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let transactionCreator: TransactionCreator
    private let ethereumNetworkProvider: EthereumNetworkProvider?

    init(tokenItem: TokenItem, feeTokenItem: TokenItem, feeProvider: any WalletModelFeeProvider, ethereumNetworkProvider: (any EthereumNetworkProvider)?) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.feeProvider = feeProvider
        self.ethereumNetworkProvider = ethereumNetworkProvider
    }

    func make() -> ExpressTransactionBuilder {
        switch tokenItem.blockchain {
        case .solana:
            UnsignedDataExpressTransactionBuilder(tokenItem: tokenItem, feeTokenItem: feeTokenItem, feeProvider: feeProvider)
        default:
            CommonExpressFeeProvider(tokenItem: tokenItem, feeTokenItem: feeTokenItem, feeProvider: feeProvider, ethereumNetworkProvider: ethereumNetworkProvider)
        }
    }
}

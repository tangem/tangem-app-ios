//
//  CustomFeeServiceFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CustomFeeServiceFactory {
    let input: CustomFeeServiceInput
    let output: CustomFeeServiceOutput
    let walletModel: WalletModel

    init(
        input: CustomFeeServiceInput,
        output: CustomFeeServiceOutput,
        walletModel: WalletModel
    ) {
        self.input = input
        self.output = output
        self.walletModel = walletModel
    }

    func makeService() -> CustomFeeService? {
        guard walletModel.supportsCustomFees else {
            return nil
        }

        let blockchain = walletModel.blockchainNetwork.blockchain
        if case .bitcoin = blockchain, let bitcoinTransactionFeeCalculator = walletModel.bitcoinTransactionFeeCalculator {
            return CustomBitcoinFeeService(
                input: input,
                output: output,
                bitcoinTransactionFeeCalculator: bitcoinTransactionFeeCalculator
            )
        } else if blockchain.isEvm {
            return CustomEvmFeeService(
                input: input,
                output: output,
                blockchain: blockchain,
                feeTokenItem: walletModel.feeTokenItem
            )
        } else {
            assertionFailure("WHY")
            return nil
        }
    }
}

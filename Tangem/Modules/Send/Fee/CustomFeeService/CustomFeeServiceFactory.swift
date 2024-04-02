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
    let walletInfo: SendWalletInfo

    init(
        input: CustomFeeServiceInput,
        output: CustomFeeServiceOutput,
        walletModel: WalletModel,
        walletInfo: SendWalletInfo
    ) {
        self.input = input
        self.output = output
        self.walletModel = walletModel
        self.walletInfo = walletInfo
    }

    func makeService() -> CustomFeeService? {
        if let utxoTransactionFeeCalculator = walletModel.utxoTransactionFeeCalculator {
            return CustomUtxoFeeService(
                input: input,
                output: output,
                utxoTransactionFeeCalculator: utxoTransactionFeeCalculator
            )
        } else if walletModel.blockchainNetwork.blockchain.isEvm {
            return CustomEvmFeeService(
                input: input,
                output: output,
                blockchain: walletModel.blockchainNetwork.blockchain,
                walletInfo: walletInfo
            )
        } else {
            return nil
        }
    }
}

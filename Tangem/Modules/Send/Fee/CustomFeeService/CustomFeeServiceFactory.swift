//
//  CustomFeeServiceFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

typealias CustomFeeServiceInput = SendModel
typealias CustomFeeServiceOutput = SendModel

struct CustomFeeServiceFactory {
    let input: CustomFeeServiceInput
    let output: CustomFeeServiceOutput
    let walletModel: WalletModel

    init(input: CustomFeeServiceInput, output: CustomFeeServiceOutput, walletModel: WalletModel) {
        self.input = input
        self.output = output
        self.walletModel = walletModel
    }

    func makeService() -> CustomFeeService? {
        if let utxoTransactionFeeCalculator = walletModel.utxoTransactionFeeCalculator {
            return CustomUtxoFeeService(input: input, output: output, utxoTransactionFeeCalculator: utxoTransactionFeeCalculator)
        } else if walletModel.blockchainNetwork.blockchain.isEvm {
            return CustomEvmFeeService(input: input, output: output, blockchain: walletModel.blockchainNetwork.blockchain)
        } else {
            return nil
        }
    }
}

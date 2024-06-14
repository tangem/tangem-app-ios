//
//  CustomFeeServiceFactory.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CustomFeeServiceFactory {
    private let walletModel: WalletModel

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }

    func makeService(
        input: CustomFeeServiceInput,
        output: CustomFeeServiceOutput
    ) -> CustomFeeService? {
        let blockchain = walletModel.blockchainNetwork.blockchain

        if case .bitcoin = blockchain,
           let bitcoinTransactionFeeCalculator = walletModel.bitcoinTransactionFeeCalculator {
            return CustomBitcoinFeeService(
                input: input,
                output: output,
                bitcoinTransactionFeeCalculator: bitcoinTransactionFeeCalculator
            )
        }

        if blockchain.isEvm {
            return CustomEvmFeeService(
                input: input,
                output: output,
                blockchain: blockchain,
                feeTokenItem: walletModel.feeTokenItem
            )
        }

        return nil
    }
}

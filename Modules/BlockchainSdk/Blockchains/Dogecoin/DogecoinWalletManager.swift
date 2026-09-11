//
//  DogecoinWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import TangemFoundation

class DogecoinWalletManager: BitcoinWalletManager {
    override var minimalFee: Decimal { 0.01 }
    override var minimalFeePerByte: Decimal {
        let dogePerKiloByte: Decimal = 0.01
        let bytesInKiloByte: Decimal = 1024

        return dogePerKiloByte / bytesInKiloByte
    }

    private var feeCalculator: DogecoinFeeCalculator {
        DogecoinFeeCalculator(
            minFee: minimalFee,
            minFeePerByte: minimalFeePerByte,
            decimalValue: wallet.blockchain.decimalValue
        )
    }

    /// https://github.com/dogecoin/dogecoin/blob/master/doc/fee-recommendation.md
    override func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        let ratesModel = feeCalculator.calculateFeeRates()

        return Future.async {
            try await self.processFee(ratesModel, amount: amount, destination: destination)
        }
        .eraseToAnyPublisher()
    }

    override func processFee(_ response: UTXOFee, amount: Amount, destination: String) async throws -> [Fee] {
        let fees = try await super.processFee(response, amount: amount, destination: destination)
        return feeCalculator.applyMinimumFees(fees)
    }
}

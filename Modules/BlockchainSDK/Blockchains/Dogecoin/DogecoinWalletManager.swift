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

    override func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        // https://github.com/dogecoin/dogecoin/blob/master/doc/fee-recommendation.md
        // Minimal fee is too small, increase it several times fold to make the transaction confirm faster.
        // It's still going to be under 1 DOGE

        let recommendedSatoshiPerByteDecimal = minimalFeePerByte * wallet.blockchain.decimalValue
        let recommendedSatoshiPerByte = recommendedSatoshiPerByteDecimal.rounded(roundingMode: .up)

        let minRate = recommendedSatoshiPerByte
        let normalRate = recommendedSatoshiPerByte * 10
        let maxRate = recommendedSatoshiPerByte * 100

        let ratesModel = UTXOFee(
            slowSatoshiPerByte: minRate,
            marketSatoshiPerByte: normalRate,
            prioritySatoshiPerByte: maxRate
        )

        return Future.async {
            try await self.processFee(ratesModel, amount: amount, destination: destination)
        }
        .eraseToAnyPublisher()
    }
}

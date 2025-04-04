//
//  KaspaFeeMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KaspaFeeMapper {
    private let blockchain: Blockchain

    init(isTestnet: Bool) {
        blockchain = .kaspa(testnet: isTestnet)
    }

    private func buckets(from feeEstimate: KaspaDTO.EstimateFee.Response) -> [KaspaDTO.EstimateFee.Response.Fee] {
        return (
            feeEstimate.lowBuckets
                + feeEstimate.normalBuckets
                + [feeEstimate.priorityBucket]
        )
        .sorted { $0.feerate > $1.feerate } // just in case, because it's not described in the documentation.
        .suffix(3) // select the 3 largest baskets
    }

    func mapFee(mass: KaspaDTO.Mass.Response, feeEstimate: KaspaDTO.EstimateFee.Response) -> [Fee] {
        let buckets = buckets(from: feeEstimate)

        let mass = Decimal(mass.mass)

        let fees = buckets.map { bucket in
            let feeRate = Decimal(bucket.feerate)
            let value = mass * feeRate / blockchain.decimalValue
            return Fee(Amount(with: blockchain, value: value))
        }

        return fees
    }

    func mapTokenFee(mass: Decimal, feeEstimate: KaspaDTO.EstimateFee.Response) -> [Fee] {
        let buckets = buckets(from: feeEstimate)

        return buckets.map { bucket in
            let feeRate = Decimal(bucket.feerate)

            let value = mass * feeRate / blockchain.decimalValue
            let commitFeeAmount = Amount(with: blockchain, value: value)

            let valueRevealFeeMock = KaspaKRC20.Constants.revealTransactionMass * feeRate / blockchain.decimalValue
            let revealFeeAmount = Amount(with: blockchain, value: valueRevealFeeMock)

            return Fee(
                commitFeeAmount + revealFeeAmount,
                parameters: KaspaKRC20.TokenTransactionFeeParams(
                    commitFee: commitFeeAmount,
                    revealFee: revealFeeAmount
                )
            )
        }
    }
}

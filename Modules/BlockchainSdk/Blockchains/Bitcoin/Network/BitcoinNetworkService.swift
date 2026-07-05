//
//  BitcoinNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class BitcoinNetworkService: MultiUTXONetworkProvider {
    override func getFee() -> AnyPublisher<UTXOFee, any Error> {
        guard !providers.isEmpty else {
            return .anyFail(error: BlockchainSdkError.noAPIInfo)
        }

        let feePublishers = providers.map { provider in
            provider
                .getFee()
                .map(Optional.some)
                .replaceError(with: nil)
                .eraseToAnyPublisher()
        }

        return Publishers.MergeMany(feePublishers)
            .collect(providers.count)
            .withWeakCaptureOf(self)
            .tryMap { try $0.aggregateFee(from: $1.compactMap { $0 }) }
            .eraseToAnyPublisher()
    }
}

private extension BitcoinNetworkService {
    func aggregateFee(from fees: [UTXOFee]) throws -> UTXOFee {
        guard !fees.isEmpty else {
            throw BlockchainSdkError.failedToLoadFee
        }

        return UTXOFee(
            slowSatoshiPerByte: aggregateValues(fees.map(\.slowSatoshiPerByte)),
            marketSatoshiPerByte: aggregateValues(fees.map(\.marketSatoshiPerByte)),
            prioritySatoshiPerByte: aggregateValues(fees.map(\.prioritySatoshiPerByte))
        )
    }

    func aggregateValues(_ values: [Decimal]) -> Decimal {
        guard !values.isEmpty else {
            return 0
        }

        if values.count == 1 {
            return values[0]
        }

        if values.count == 2 {
            return (values[0] + values[1]) / Decimal(2)
        }

        let sortedValues = values.sorted()
        let trimmedValues = Array(sortedValues.dropFirst().dropLast())
        let sum = trimmedValues.reduce(Decimal(0), +)
        return sum / Decimal(trimmedValues.count)
    }
}

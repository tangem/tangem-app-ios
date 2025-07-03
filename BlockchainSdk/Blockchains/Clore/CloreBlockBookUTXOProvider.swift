//
//  CloreBlockBookUTXOProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CloreBlockBookUTXOProvider: BlockBookUTXOProvider {
    override func getFeeRatePerByte(for confirmationBlocks: Int) -> AnyPublisher<Decimal, any Error> {
        executeRequest(.getFees(confirmationBlocks: confirmationBlocks), responseType: JSONRPC.DefaultResponse<String>.self)
            .withWeakCaptureOf(self)
            .tryMap { provider, response in
                let result = try response.result.get()

                guard let decimalFeeResult = Decimal(stringValue: result) else {
                    throw BlockchainSdkError.failedToGetFee
                }

                let recommendedDecimalFeeResult = decimalFeeResult * Constants.recommendedRateMultiplyFeeResult

                return try provider.convertFeeRate(recommendedDecimalFeeResult)
            }
            .eraseToAnyPublisher()
    }
}

extension CloreBlockBookUTXOProvider {
    enum Constants {
        static let recommendedRateMultiplyFeeResult: Decimal = .init(stringValue: "1.5")!
    }
}

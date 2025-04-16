//
//  CloreBlockBookUTXOProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

class CloreBlockBookUTXOProvider: BlockBookUTXOProvider {
    override func getFeeRatePerByte(for confirmationBlocks: Int) -> AnyPublisher<Decimal, any Error> {
        executeRequest(.getFees(confirmationBlocks: confirmationBlocks), responseType: JSONRPC.DefaultResponse<String>.self)
            .withWeakCaptureOf(self)
            .tryMap { provider, response in
                let result = try response.result.get()

                guard let decimalFeeResult = Decimal(stringValue: result) else {
                    throw WalletError.failedToGetFee
                }

                return try provider.convertFeeRate(decimalFeeResult)
            }
            .eraseToAnyPublisher()
    }
}

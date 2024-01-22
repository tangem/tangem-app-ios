//
//  SendFeeViewModelInputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BigInt
import BlockchainSdk

class SendFeeViewModelInputMock: SendFeeViewModelInput {
    var customGasLimit: BigUInt? {
        nil
    }

    var customFeePublisher: AnyPublisher<Fee?, Never> {
        .just(output: nil)
    }

    var customGasPricePublisher: AnyPublisher<BigUInt?, Never> {
        .just(output: nil)
    }

    var customGasLimitPublisher: AnyPublisher<BigUInt?, Never> {
        .just(output: nil)
    }

    var selectedFeeOption: FeeOption {
        .market
    }

    var feeOptions: [FeeOption] {
        [.slow, .market, .fast, .custom]
    }

    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> {
        .just(output: [
            .slow: .loaded(.init(.init(with: .ethereum(testnet: false), type: .coin, value: 1))),
            .market: .loaded(.init(.init(with: .ethereum(testnet: false), type: .coin, value: 2))),
            .fast: .loaded(.init(.init(with: .ethereum(testnet: false), type: .coin, value: 3))),
        ])
    }

    func didSelectFeeOption(_ feeOption: FeeOption) {}
    func didChangeCustomFee(_ value: Fee?) {}
    func didChangeCustomFeeGasPrice(_ value: BigUInt?) {}
    func didChangeCustomFeeGasLimit(_ value: BigUInt?) {}
}

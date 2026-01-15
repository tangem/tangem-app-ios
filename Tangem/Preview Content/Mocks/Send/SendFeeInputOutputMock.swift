//
//  SendFeeInputOutputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

final class SendFeeInputOutputMock: SendFeeInput, SendFeeOutput {
    var selectedFee: LoadableTokenFee? {
        LoadableTokenFee(
            option: .market,
            tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: .none)),
            value: .success(.init(.init(with: .polygon(testnet: false), value: 0.1)))
        )
    }

    var selectedFeePublisher: AnyPublisher<LoadableTokenFee?, Never> { .just(output: selectedFee) }
    var hasMultipleFeeOptions: AnyPublisher<Bool, Never> { .just(output: false) }
    var cryptoAmountPublisher: AnyPublisher<Decimal, Never> { .just(output: 1) }
    var destinationAddressPublisher: AnyPublisher<String?, Never> { .just(output: "0x") }

    func feeDidChanged(fee: LoadableTokenFee) {}
}

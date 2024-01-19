//
//  SendFeeViewModelInputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class SendFeeViewModelInputMock: SendFeeViewModelInput {
    var selectedFeeOption: FeeOption {
        .market
    }

    var feeOptions: [FeeOption] {
        [.slow, .market, .fast]
    }

    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> {
        .just(output: [
            .slow: .loading,
            .market: .loading,
            .fast: .loading,
        ])
    }

    func didSelectFeeOption(_ feeOption: FeeOption) {}
}

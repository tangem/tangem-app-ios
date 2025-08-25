//
//  NFTSendAmountModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct NFTSendAmountModifier: SendAmountModifier {
    var modifyingMessagePublisher: AnyPublisher<String?, Never> {
        return .just(output: nil)
    }

    private let amount: Decimal

    init(amount: Decimal) {
        self.amount = amount
    }

    func modify(cryptoAmount: Decimal?) -> Decimal? {
        return amount
    }
}

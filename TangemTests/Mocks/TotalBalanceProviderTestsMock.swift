//
//  MockTotalBalanceProvider.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
@testable import Tangem

final class TotalBalanceProviderTestsMock: TotalBalanceProvider {
    var totalBalance: TotalBalanceState = .empty

    private let totalBalanceSubject = CurrentValueSubject<TotalBalanceState, Never>(.empty)

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }

    func sendUpdate() {
        totalBalanceSubject.send(totalBalance)
    }
}

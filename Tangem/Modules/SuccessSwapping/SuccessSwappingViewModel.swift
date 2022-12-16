//
//  SuccessSwappingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class SuccessSwappingViewModel: ObservableObject, Identifiable {
    let id = UUID()

    // MARK: - ViewState

    var sourceFormatted: String {
        sourceCurrencyAmount.formatted
    }

    var resultFormatted: String {
        resultCurrencyAmount.formatted
    }

    // MARK: - Dependencies

    private let sourceCurrencyAmount: CurrencyAmount
    private let resultCurrencyAmount: CurrencyAmount
    private unowned let coordinator: SuccessSwappingRoutable

    init(
        sourceCurrencyAmount: CurrencyAmount,
        resultCurrencyAmount: CurrencyAmount,
        coordinator: SuccessSwappingRoutable
    ) {
        self.sourceCurrencyAmount = sourceCurrencyAmount
        self.resultCurrencyAmount = resultCurrencyAmount
        self.coordinator = coordinator
    }

    func doneDidTapped() {
        coordinator.didTapMainButton()
    }
}

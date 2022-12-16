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
        sourcePrice.formatted
    }

    var resultFormatted: String {
        resultPrice.formatted
    }

    // MARK: - Dependencies

    private let sourcePrice: CurrencyAmount
    private let resultPrice: CurrencyAmount
    private unowned let coordinator: SuccessSwappingRoutable

    init(
        sourcePrice: CurrencyAmount,
        resultPrice: CurrencyAmount,
        coordinator: SuccessSwappingRoutable
    ) {
        self.sourcePrice = sourcePrice
        self.resultPrice = resultPrice
        self.coordinator = coordinator
    }

    func doneDidTapped() {
        coordinator.didTapMainButton()
    }
}

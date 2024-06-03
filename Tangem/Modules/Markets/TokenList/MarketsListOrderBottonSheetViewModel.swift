//
//  MarketsListOrderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import CombineExt
import SwiftUI

class MarketsListOrderBottonSheetViewModel: ObservableObject, Identifiable {
    @Published var listOptionViewModel: [DefaultSelectableRowViewModel<MarketsListOrderType>] = []
    @Published var currentOrderType: MarketsListOrderType

    var didUpdateOrder: ((_ type: MarketsListOrderType) -> Void)?

    // MARK: - Private Properties

    private var subscription: AnyCancellable?

    // MARK: - Init

    init(currentOrderType: MarketsListOrderType, _ didUpdateOrder: ((_ type: MarketsListOrderType) -> Void)?) {
        self.currentOrderType = currentOrderType
        self.didUpdateOrder = didUpdateOrder
        setup()
    }

    private func setup() {
        bind()

        listOptionViewModel = MarketsListOrderType.allCases.map {
            DefaultSelectableRowViewModel(
                id: $0,
                title: $0.description,
                subtitle: nil
            )
        }
    }

    private func bind() {
        subscription = $currentOrderType
            .removeDuplicates()
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, newOption in
                viewModel.update(option: newOption)
            })
    }

    private func update(option: MarketsListOrderType) {
        currentOrderType = option
        didUpdateOrder?(option)
    }
}

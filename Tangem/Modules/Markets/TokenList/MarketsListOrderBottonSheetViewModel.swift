//
//  MarketsListOrderViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 03.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import CombineExt
import SwiftUI

class MarketsListOrderBottonSheetViewModel: ObservableObject, Identifiable {
    @Published var listOptionViewModel: [DefaultSelectableRowViewModel<MarketsListOrderType>]
    @Published var currentOrderType: MarketsListOrderType

    // MARK: - Private Properties

    private var subscription: AnyCancellable?
    private weak var delegate: MarketsListOrderBottonSheetViewModelDelegate?

    // MARK: - Init

    init(from provider: MarketsListDataFilterProvider) {
        currentOrderType = provider.orderType
        delegate = provider

        listOptionViewModel = provider.supportedOrderTypes.map {
            DefaultSelectableRowViewModel(
                id: $0,
                title: $0.description,
                subtitle: nil
            )
        }

        bind()
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
        delegate?.didSelect(option: option)
    }
}

protocol MarketsListOrderBottonSheetViewModelDelegate: AnyObject {
    func didSelect(option: MarketsListOrderType)
}

//
//  MarketRaitingHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketRaitingHeaderViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var marketListOrderType: MarketsListOrderType
    @Published var marketPriceIntervalType: MarketsPriceIntervalType

    // MARK: - Private Properties

    private weak var delegate: MarketRaitingHeaderViewModelDelegate?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(from provider: MarketsListDataFilterProvider) {
        delegate = provider
        marketListOrderType = provider.orderType
        marketPriceIntervalType = provider.intervalType
        bind(with: provider.filterPublisher)
    }

    func bind(with filterPublisher: some Publisher<MarketsListDataProvider.Filter, Never>) {
        $marketPriceIntervalType
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                viewModel.delegate?.marketPriceIntervalButtonDidTap(value)
            }
            .store(in: &bag)

        filterPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, filter in
                viewModel.marketListOrderType = filter.order
                viewModel.marketPriceIntervalType = filter.interval
            }
            .store(in: &bag)
    }

    func onOrderActionButtonDidTap() {
        delegate?.marketOrderActionButtonDidTap()
    }
}

protocol MarketRaitingHeaderViewModelDelegate: AnyObject {
    func marketOrderActionButtonDidTap()
    func marketPriceIntervalButtonDidTap(_ interval: MarketsPriceIntervalType)
}

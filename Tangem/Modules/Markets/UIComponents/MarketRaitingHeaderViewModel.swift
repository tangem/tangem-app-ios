//
//  MarketRaitingHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol MarketOrderHeaderViewModelOrderDelegate: AnyObject {
    func marketOrderActionButtonDidTap()
}

class MarketRatingHeaderViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var marketListOrderType: MarketsListOrderType
    @Published var marketPriceIntervalType: MarketsPriceIntervalType

    var marketPriceIntervalTypeOptions: [MarketsPriceIntervalType] = []

    weak var delegate: MarketOrderHeaderViewModelOrderDelegate?

    // MARK: - Private Properties

    private var bag = Set<AnyCancellable>()

    private let provider: MarketsListDataFilterProvider

    // MARK: - Init

    init(provider: MarketsListDataFilterProvider) {
        self.provider = provider

        marketListOrderType = provider.currentFilterValue.order
        marketPriceIntervalType = provider.currentFilterValue.interval
        marketPriceIntervalTypeOptions = provider.supportedPriceIntervalTypes

        bind(with: provider.filterPublisher)
    }

    func bind(with filterPublisher: some Publisher<MarketsListDataProvider.Filter, Never>) {
        $marketPriceIntervalType
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                viewModel.provider.didSelectMarketPriceInterval(value)
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

//
//  MarketsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class MarketsViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Published var alert: AlertBinder?
    @Published var tokenViewModels: [MarketsItemViewModel] = []
    @Published var viewDidAppear: Bool = false
    @Published var marketsRatingHeaderViewModel: MarketsRatingHeaderViewModel
    @Published var isLoading: Bool = false

    // MARK: - Properties

    var hasNextPage: Bool {
        dataProvider.canFetchMore
    }

    private weak var coordinator: MarketsRoutable?

    private var dataSource: MarketsDataSource

    private let filterProvider = MarketsListDataFilterProvider()
    private let dataProvider = MarketsListDataProvider()

//    private lazy var loader = setupListDataLoader()

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        searchTextPublisher: some Publisher<String, Never>,
        coordinator: MarketsRoutable
    ) {
        self.coordinator = coordinator
        dataSource = MarketsDataSource()

        marketsRatingHeaderViewModel = MarketsRatingHeaderViewModel(provider: filterProvider)
        marketsRatingHeaderViewModel.delegate = self

        searchTextBind(searchTextPublisher: searchTextPublisher)
        searchFilterBind(filterPublisher: filterProvider.filterPublisher)

        dataProviderBind()
    }

    func onBottomAppear() {
        // Need for locked fetchMore process when bottom sheet not yet open
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewDidAppear = true
        }

        Analytics.log(.manageTokensScreenOpened)
    }

    func onBottomDisappear() {
        dataProvider.reset(nil, with: nil)
        fetch(with: "", by: filterProvider.currentFilterValue)
        viewDidAppear = false
    }

    func fetchMore() {
        dataProvider.fetchMore()
    }

    func addCustomTokenDidTapAction() {
        Analytics.log(.manageTokensButtonCustomToken)
        coordinator?.openAddCustomToken(dataSource: dataSource)
    }
}

// MARK: - Private Implementation

private extension MarketsViewModel {
    func fetch(with searchText: String = "", by filter: MarketsListDataProvider.Filter) {
        dataProvider.fetch(searchText, with: filter)
    }

    func searchTextBind(searchTextPublisher: (some Publisher<String, Never>)?) {
        searchTextPublisher?
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                viewModel.fetch(with: value, by: viewModel.dataProvider.lastFilterValue ?? viewModel.filterProvider.currentFilterValue)
            }
            .store(in: &bag)
    }

    func searchFilterBind(filterPublisher: (some Publisher<MarketsListDataProvider.Filter, Never>)?) {
        filterPublisher?
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                viewModel.fetch(with: viewModel.dataProvider.lastSearchTextValue ?? "", by: viewModel.filterProvider.currentFilterValue)
            }
            .store(in: &bag)
    }

    func dataProviderBind() {
        dataProvider.$items
            .receive(on: DispatchQueue.main)
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { provider, items in
                provider.tokenViewModels = items.compactMap { provider.mapToTokenViewModel(tokenItemModel: $0) }
            })
            .store(in: &bag)

        dataProvider.$isLoading
            .receive(on: DispatchQueue.main)
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, isLoading in
                // It is necessary to hide it under this condition for disable to eliminate the flickering of the animation
                viewModel.isLoading = isLoading
            })
            .store(in: &bag)
    }

    // MARK: - Private Implementation

    private func mapToTokenViewModel(tokenItemModel: MarketsTokenModel) -> MarketsItemViewModel {
        let inputData = MarketsItemViewModel.InputData(
            id: tokenItemModel.id,
            name: tokenItemModel.name,
            symbol: tokenItemModel.symbol,
            marketCap: tokenItemModel.marketCap,
            marketRating: tokenItemModel.marketRating,
            priceValue: tokenItemModel.currentPrice,
            priceChangeStateValue: tokenItemModel.priceChangePercentage[filterProvider.currentFilterValue.interval.rawValue]
        )

        return MarketsItemViewModel(inputData)
    }
}

extension MarketsViewModel: MarketsOrderHeaderViewModelOrderDelegate {
    func orderActionButtonDidTap() {
        coordinator?.openFilterOrderBottonSheet(with: filterProvider)
    }
}

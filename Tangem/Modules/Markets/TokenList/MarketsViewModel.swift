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
    @Published var isShowAddCustomToken: Bool = false
    @Published var tokenViewModels: [MarketsItemViewModel] = []
    @Published var viewDidAppear: Bool = false
    @Published var marketRatingHeaderViewModel: MarketRatingHeaderViewModel

    // MARK: - Properties

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    private weak var coordinator: MarketsRoutable?

    private var dataSource: MarketsDataSource
    private let filterProvider = MarketsListDataFilterProvider()
    private lazy var loader = setupListDataLoader()

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        searchTextPublisher: some Publisher<String, Never>,
        coordinator: MarketsRoutable
    ) {
        self.coordinator = coordinator
        dataSource = MarketsDataSource()

        marketRatingHeaderViewModel = MarketRatingHeaderViewModel(from: filterProvider)
        searchBind(searchTextPublisher: searchTextPublisher)

        filterProvider.onUpdateOrderAction = { [weak self] in
            guard let self else { return }
            coordinator.openFilterOrderBottonSheet(with: filterProvider)
        }

        bind()
    }

    func onBottomAppear() {
        // Need for locked fetchMore process when bottom sheet not yet open
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewDidAppear = true
        }

        Analytics.log(.manageTokensScreenOpened)
    }

    func onBottomDisappear() {
        loader.reset(nil)
        fetch(with: "")
        viewDidAppear = false
    }

    func fetchMore() {
        loader.fetchMore()
    }

    func addCustomTokenDidTapAction() {
        Analytics.log(.manageTokensButtonCustomToken)
        coordinator?.openAddCustomToken(dataSource: dataSource)
    }
}

// MARK: - Private Implementation

private extension MarketsViewModel {
    func fetch(with searchText: String = "") {
        loader.fetch(searchText)
    }

    func searchBind(searchTextPublisher: (some Publisher<String, Never>)?) {
        searchTextPublisher?
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] value in
                if !value.isEmpty {
                    Analytics.log(.manageTokensSearched)

                    // It is necessary to hide it under this condition for disable to eliminate the flickering of the animation
                    self?.setNeedDisplayTokensListSkeletonView()
                }

                self?.fetch(with: value)
            }
            .store(in: &bag)
    }

    func bind() {
        dataSource
            .userWalletModelsPublisher
            .sink { [weak self] models in
                self?.fetch()
            }
            .store(in: &bag)
    }

    func setupListDataLoader() -> ListDataLoader {
        let supportedBlockchains = SupportedBlockchains.all
        let loader = ListDataLoader(supportedBlockchains: supportedBlockchains)

        loader.$items
            .receive(on: DispatchQueue.main)
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] items in
                guard let self = self else {
                    return
                }

                tokenViewModels = items.compactMap { self.mapToTokenViewModel(coinModel: $0) }

                isShowAddCustomToken = tokenViewModels.isEmpty && !dataSource.userWalletModels.contains(where: { $0.config.hasFeature(.multiCurrency) })

                if let searchValue = loader.lastSearchTextValue, !searchValue.isEmpty, items.isEmpty {
                    Analytics.log(event: .manageTokensTokenIsNotFound, params: [.input: searchValue])
                }
            })
            .store(in: &bag)

        return loader
    }

    // MARK: - Private Implementation

    /// Need for display list skeleton view
    private func setNeedDisplayTokensListSkeletonView() {
        // [REDACTED_TODO_COMMENT]
//        tokenViewModels = [Int](0 ... 10).map { _ in }
    }

    private func mapToTokenViewModel(coinModel: CoinModel) -> MarketsItemViewModel {
        // [REDACTED_TODO_COMMENT]
        let inputData = MarketsItemViewModel.InputData(
            id: coinModel.id,
            imageURL: IconURLBuilder().tokenIconURL(id: coinModel.id, size: .large).absoluteString,
            name: coinModel.name,
            symbol: coinModel.symbol,
            marketCap: "",
            marketRating: "",
            priceValue: nil,
            priceChangeStateValue: nil
        )

        return MarketsItemViewModel(inputData)
    }
}

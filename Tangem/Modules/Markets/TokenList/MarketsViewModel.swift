//
//  MarketsViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 14.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class MarketsViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Injected(\.quotesRepository) private var tokenQuotesRepository: TokenQuotesRepository

    @Published var alert: AlertBinder?
    @Published var isShowAddCustomToken: Bool = false
    @Published var tokenViewModels: [MarketsItemViewModel] = []
    @Published var viewDidAppear: Bool = false

    // MARK: - Properties

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    private let loader = MarketsListDataProvider()
    private var filter = MarketsListDataProvider.Filter()

    private weak var coordinator: MarketsRoutable?

    private var dataSource: MarketsDataSource

    private var bag = Set<AnyCancellable>()
    private var cacheExistListCoinId: [String] = []
    private var pendingDerivationCountByWalletId: [UserWalletId: Int] = [:]

    // MARK: - Init

    init(
        searchTextPublisher: some Publisher<String, Never>,
        coordinator: MarketsRoutable
    ) {
        self.coordinator = coordinator
        dataSource = MarketsDataSource()

        searchBind(searchTextPublisher: searchTextPublisher)

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
        loader.reset("", with: filter)
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
        loader.fetch(searchText, with: filter)
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
        loader.$items
            .receive(on: DispatchQueue.main)
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] items in
                guard let self = self else {
                    return
                }

                tokenViewModels = items.compactMap {
                    return self.mapToViewModel(token: $0)
                }

                updateQuote(by: items.map { $0.id })

                isShowAddCustomToken = tokenViewModels.isEmpty && !dataSource.userWalletModels.contains(where: { $0.config.hasFeature(.multiCurrency) })

                if let searchValue = loader.lastSearchTextValue, !searchValue.isEmpty, items.isEmpty {
                    Analytics.log(event: .manageTokensTokenIsNotFound, params: [.input: searchValue])
                }
            })
            .store(in: &bag)

        dataSource
            .userWalletModelsPublisher
            .sink { [weak self] models in
                self?.fetch()
            }
            .store(in: &bag)
    }

    // MARK: - Private Implementation

    /// Need for display list skeleton view
    private func setNeedDisplayTokensListSkeletonView() {
//        tokenViewModels = [Int](0 ... 10).map { _ in
//            let dummyInputData = MarketsItemViewModel.InputData(token: .dummy, state: .loading)
//            return MarketsItemViewModel(dummyInputData)
//        }
    }

    private func mapToViewModel(token: MarketTokenModel) -> MarketsItemViewModel {
        let inputData = MarketsItemViewModel.InputData(
            id: token.id,
            imageURL: token.imageURL,
            name: token.name,
            symbol: token.symbol,
            marketCup: token.marketCup,
            marketRaiting: token.marketRaiting,
            priceValue: token.currentPrice,
            priceChangeStateValue: token.priceChangePercentage[filter.interval]
        )

        return MarketsItemViewModel(inputData)
    }

    private func updateQuote(by coinIds: [String]) {
        runTask(in: self) { root in
            await root.tokenQuotesRepository.loadQuotes(currencyIds: coinIds)
        }
    }

    private func updateGenerateAddressesViewModel() {
        let countWalletPendingDerivation = pendingDerivationCountByWalletId.filter { $0.value > 0 }.count

        guard countWalletPendingDerivation > 0 else {
            coordinator?.hideGenerateAddressesWarning()
            return
        }

        Analytics.log(
            event: .manageTokensButtonGetAddresses,
            params: [
                .walletCount: String(countWalletPendingDerivation),
                .source: Analytics.ParameterValue.manageTokens.rawValue,
            ]
        )

        coordinator?.showGenerateAddressesWarning(
            numberOfNetworks: pendingDerivationCountByWalletId.map(\.value).reduce(0, +),
            currentWalletNumber: pendingDerivationCountByWalletId.filter { $0.value > 0 }.count,
            totalWalletNumber: dataSource.userWalletModels.count,
            action: weakify(self, forFunction: MarketsViewModel.generateAddressByWalletPendingDerivations)
        )
    }

    private func generateAddressByWalletPendingDerivations() {
        guard let userWalletId = pendingDerivationCountByWalletId.first(where: { $0.value > 0 })?.key else {
            return
        }

        guard let userWalletModel = dataSource.userWalletModels.first(where: { $0.userWalletId == userWalletId }) else {
            return
        }

        userWalletModel.userTokensManager.deriveIfNeeded { result in
            if case .failure(let error) = result, !error.isUserCancelled {
                self.alert = error.alertBinder
            }
        }
    }
}

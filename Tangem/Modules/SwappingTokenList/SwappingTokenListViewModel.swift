//
//  SwappingTokenListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class SwappingTokenListViewModel: ObservableObject, Identifiable {
    /// For SwiftUI sheet logic
    let id = UUID()

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - ViewState

    // I can't use @Published here, because of swiftui redraw perfomance drop
    var searchText = CurrentValueSubject<String, Never>("")
    @Published var yourItems: [SwappingTokenItemViewModel] = []
    @Published var otherItems: [SwappingTokenItemViewModel] = []

    var hasNextPage: Bool {
        dataLoader.canFetchMore
    }

    // MARK: - Dependencies

    private unowned let coordinator: SwappingTokenListRoutable

    private let networkIds: [String]
    private var bag: Set<AnyCancellable> = []
    private lazy var dataLoader: ListDataLoader = setupLoader()

    init(
        networkIds: [String],
        coordinator: SwappingTokenListRoutable
    ) {
        self.networkIds = networkIds
        self.coordinator = coordinator

        bind()
    }

    func onAppear() {
        dataLoader.reset(searchText.value)
    }

    func fetch() {
        dataLoader.fetch(searchText.value)
    }
}

private extension SwappingTokenListViewModel {
    func bind() {
        searchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] string in
                self?.dataLoader.fetch(string)
            }
            .store(in: &bag)
    }

    func setupLoader() -> ListDataLoader {
        let dataLoader = ListDataLoader(networkIds: networkIds, exchangeable: true)
        dataLoader.$items
            .receive(on: DispatchQueue.global())
            .map { coinModels in
                coinModels.map { model in
                    SwappingTokenItemViewModel(
                        iconURL: model.imageURL,
                        name: model.name,
                        symbol: model.symbol,
                        fiatBalance: nil,
                        balance: nil
                    ) { [weak self] in
                        self?.userDidTap(coinModel: model)
                    }
                }
            }
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.otherItems, on: self)
            .store(in: &bag)

        return dataLoader
    }

    func userDidTap(coinModel: CoinModel) {
        coordinator.userDidTap(coinModel: coinModel)
    }
}

private extension Currency {
    
}

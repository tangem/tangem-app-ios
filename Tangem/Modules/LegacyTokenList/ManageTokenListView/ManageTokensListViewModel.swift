//
//  ManageTokensListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

class ManageTokensListViewModel: ObservableObject {
    @Published var coinViewModels: [LegacyCoinViewModel] = []

    var hasNextPage: Bool {
        loader.hasNextPage
    }

    private unowned let loader: ManageTokensListLoader
    private let coinViewModelsPublisher: any Publisher<[LegacyCoinViewModel], Never>
    private var bag = Set<AnyCancellable>()

    init(
        loader: ManageTokensListLoader,
        coinViewModelsPublisher: some Publisher<[LegacyCoinViewModel], Never>
    ) {
        self.loader = loader
        self.coinViewModelsPublisher = coinViewModelsPublisher

        bind()
    }

    func fetch() {
        loader.fetch()
    }

    func bind() {
        coinViewModelsPublisher
            .assign(to: \.coinViewModels, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

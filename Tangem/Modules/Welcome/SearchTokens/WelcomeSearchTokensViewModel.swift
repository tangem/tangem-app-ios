//
//  WelcomeSearchTokensViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class WelcomeSearchTokensViewModel: Identifiable, ObservableObject {
    // I can't use @Published here, because of swiftui redraw perfomance drop
    var enteredSearchText = CurrentValueSubject<String, Never>("")

    @Published var coinViewModels: [LegacyCoinViewModel] = []
    @Published var isLoading: Bool = true

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    private lazy var loader = setupListDataLoader()
    private var bag = Set<AnyCancellable>()

    init() {
        bind()
    }

    func onAppear() {
        loader.reset(enteredSearchText.value)
    }

    func onDisappear() {
        DispatchQueue.main.async {
            self.enteredSearchText.value = ""
        }
    }

    func fetch() {
        loader.fetch(enteredSearchText.value)
    }
}

// MARK: - Private

private extension WelcomeSearchTokensViewModel {
    func bind() {
        enteredSearchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] string in
                if !string.isEmpty {
                    Analytics.log(.manageTokensSearched)
                }

                self?.loader.fetch(string)
            }
            .store(in: &bag)
    }

    func setupListDataLoader() -> ListDataLoader {
        let supportedBlockchains = SupportedBlockchains.all
        let loader = ListDataLoader(supportedBlockchains: supportedBlockchains)

        loader.$items
            .withWeakCaptureOf(self)
            .map { viewModel, items -> [LegacyCoinViewModel] in
                items.compactMap(viewModel.mapToCoinViewModel(coinModel:))
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.coinViewModels, on: self, ownership: .weak)
            .store(in: &bag)

        return loader
    }

    func mapToCoinViewModel(coinModel: CoinModel) -> LegacyCoinViewModel {
        let currencyItems = coinModel.items.enumerated().map { index, item in
            LegacyCoinItemViewModel(
                tokenItem: item.tokenItem,
                isReadonly: true,
                isSelected: .constant(false),
                isCopied: .constant(false),
                position: .init(with: index, total: coinModel.items.count)
            )
        }

        return LegacyCoinViewModel(with: coinModel, items: currencyItems)
    }
}

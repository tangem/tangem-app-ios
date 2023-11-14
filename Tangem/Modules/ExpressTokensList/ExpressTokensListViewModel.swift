//
//  ExpressTokensListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSwapping

final class ExpressTokensListViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var searchText: String = ""
    @Published var availableTokens: [ExpressTokenItemViewModel] = []
    @Published var unavailableTokens: [ExpressTokenItemViewModel] = []

    var unavailableSectionHeader: String {
        Localization.exchangeTokensUnavailableTokensHeader(initialWalletType.name)
    }

    // MARK: - Dependencies

    private let initialWalletType: InitialWalletType
    private let walletModels: [WalletModel]
    private let expressAPIProvider: ExpressAPIProvider
    private unowned let expressInteractor: ExpressInteractor
    private unowned let coordinator: ExpressTokensListRoutable

    // MARK: - Internal

    private var availableWalletModels: [WalletModel] = []
    private var unavailableWalletModels: [WalletModel] = []
    private var bag: Set<AnyCancellable> = []

    init(
        initialWalletType: InitialWalletType,
        walletModels: [WalletModel],
        expressAPIProvider: ExpressAPIProvider,
        expressInteractor: ExpressInteractor,
        coordinator: ExpressTokensListRoutable
    ) {
        self.initialWalletType = initialWalletType
        self.walletModels = walletModels
        self.expressAPIProvider = expressAPIProvider
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        bind()
        loadView()
    }
}

// MARK: - Private

private extension ExpressTokensListViewModel {
    func loadView() {
        runTask(in: self) { viewModel in
            let availablePairs = try await viewModel.loadAvailablePairs()
            viewModel.updateWalletModels(availableCurrencies: availablePairs)
        }
    }

    func loadAvailablePairs() async throws -> [ExpressCurrency] {
        let currencies = walletModels.map { $0.currency }

        switch initialWalletType {
        case .source(let wallet):
            let pairs = try await expressAPIProvider.pairs(from: [wallet.currency], to: currencies)
            return pairs.map { $0.source }
        case .destination(let wallet):
            let pairs = try await expressAPIProvider.pairs(from: currencies, to: [wallet.currency])
            return pairs.map { $0.destination }
        }
    }

    func updateWalletModels(availableCurrencies: [ExpressCurrency]) {
        availableWalletModels = walletModels.filter { walletModel in
            availableCurrencies.contains { walletModel.currency == $0 }
        }

        unavailableWalletModels = walletModels.filter { walletModel in
            !availableCurrencies.contains { walletModel.currency == $0 }
        }

        updateView()
    }

    func bind() {
        $searchText
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                self?.updateView(searchText: searchText)
            }
            .store(in: &bag)
    }

    func updateView(searchText: String = "") {
        if searchText.isEmpty {
            availableTokens = availableWalletModels.map { walletModel in
                mapToExpressTokenItemViewModel(walletModel: walletModel, isDisable: false)
            }

            unavailableTokens = availableWalletModels.map { walletModel in
                mapToExpressTokenItemViewModel(walletModel: walletModel, isDisable: true)
            }
        } else {
            availableTokens = availableWalletModels
                .filter { $0.name.contains(searchText) }
                .map { walletModel in
                    mapToExpressTokenItemViewModel(walletModel: walletModel, isDisable: false)
                }

            unavailableTokens = availableWalletModels
                .filter { $0.name.contains(searchText) }
                .map { walletModel in
                    mapToExpressTokenItemViewModel(walletModel: walletModel, isDisable: true)
                }
        }
    }

    func mapToExpressTokenItemViewModel(walletModel: WalletModel, isDisable: Bool) -> ExpressTokenItemViewModel {
        ExpressTokenItemViewModel(
            id: walletModel.id,
            tokenIconItem: TokenIconItemViewModel(tokenItem: walletModel.tokenItem),
            name: walletModel.tokenItem.name,
            symbol: walletModel.tokenItem.currencySymbol,
            balance: walletModel.balance,
            fiatBalance: walletModel.fiatBalance,
            isDisable: isDisable,
            itemDidTap: { [weak self] in
                self?.userDidTap(on: walletModel)
            }
        )
    }

    func userDidTap(on walletModel: WalletModel) {
        switch initialWalletType {
        case .source:
            // [REDACTED_TODO_COMMENT]
            // expressInteractor.update(destination: walletModel)
            break
        case .destination:
            // [REDACTED_TODO_COMMENT]
            // expressInteractor.update(source: walletModel)
            break
        }

        coordinator.closeExpressTokensList()
    }
}

extension ExpressTokensListViewModel {
    enum InitialWalletType {
        case source(WalletModel)
        case destination(WalletModel)

        var name: String {
            switch self {
            case .source(let walletModel):
                return walletModel.name
            case .destination(let walletModel):
                return walletModel.name
            }
        }
    }
}

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

    var isEmptyView: Bool {
        searchText.isEmpty && availableTokens.isEmpty && unavailableTokens.isEmpty
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
        self.walletModels = walletModels.filter { $0 != initialWalletType.wallet }
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
        var currencies = walletModels.map { $0.currency }

        switch initialWalletType {
        case .source(let wallet):
            let pairs = try await expressAPIProvider.pairs(from: [wallet.currency], to: currencies)
            return pairs.map { $0.destination }
        case .destination(let wallet):
            let pairs = try await expressAPIProvider.pairs(from: currencies, to: [wallet.currency])
            return pairs.map { $0.source }
        }
    }

    func updateWalletModels(availableCurrencies: [ExpressCurrency]) {
        availableWalletModels.removeAll()
        unavailableWalletModels.removeAll()

        walletModels.forEach { walletModel in
            let isAvailable = availableCurrencies.contains { walletModel.currency == $0 }
            if isAvailable {
                availableWalletModels.append(walletModel)
            } else {
                unavailableWalletModels.append(walletModel)
            }
        }

        updateView()
    }

    func bind() {
        $searchText
            .dropFirst()
            .removeDuplicates()
            .flatMapLatest { searchText in
                // We don't add debounce for the empty text
                if searchText.isEmpty {
                    return Just(searchText).eraseToAnyPublisher()
                }

                return Just(searchText)
                    .delay(for: .seconds(0.3), scheduler: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
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

            unavailableTokens = unavailableWalletModels.map { walletModel in
                mapToExpressTokenItemViewModel(walletModel: walletModel, isDisable: true)
            }
        } else {
            availableTokens = availableWalletModels
                .filter { $0.name.lowercased().contains(searchText.lowercased()) }
                .map { walletModel in
                    mapToExpressTokenItemViewModel(walletModel: walletModel, isDisable: false)
                }

            unavailableTokens = unavailableWalletModels
                .filter { $0.name.lowercased().contains(searchText.lowercased()) }
                .map { walletModel in
                    mapToExpressTokenItemViewModel(walletModel: walletModel, isDisable: true)
                }
        }
    }

    func mapToExpressTokenItemViewModel(walletModel: WalletModel, isDisable: Bool) -> ExpressTokenItemViewModel {
        ExpressTokenItemViewModel(
            id: walletModel.id,
            tokenIconItem: TokenIconItemViewModel(tokenItem: walletModel.tokenItem),
            name: walletModel.name,
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

        var wallet: WalletModel {
            switch self {
            case .source(let walletModel):
                return walletModel
            case .destination(let walletModel):
                return walletModel
            }
        }
    }
}

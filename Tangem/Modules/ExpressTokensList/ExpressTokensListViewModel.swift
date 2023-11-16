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
        Localization.exchangeTokensUnavailableTokensHeader(swapDirection.name)
    }

    var isEmptyView: Bool {
        searchText.isEmpty && availableTokens.isEmpty && unavailableTokens.isEmpty
    }

    // MARK: - Dependencies

    private let swapDirection: SwapDirection
    private let walletModels: [WalletModel]
    private let expressAPIProvider: ExpressAPIProvider
    private unowned let expressInteractor: ExpressInteractor
    private unowned let coordinator: ExpressTokensListRoutable

    // MARK: - Internal

    private var availableWalletModels: [WalletModel] = []
    private var unavailableWalletModels: [WalletModel] = []
    private var bag: Set<AnyCancellable> = []

    init(
        swapDirection: SwapDirection,
        walletModels: [WalletModel],
        expressAPIProvider: ExpressAPIProvider,
        expressInteractor: ExpressInteractor,
        coordinator: ExpressTokensListRoutable
    ) {
        self.swapDirection = swapDirection
        self.walletModels = walletModels
        self.expressAPIProvider = expressAPIProvider
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        bind()
    }

    func onAppear() {
        initialSetup()
    }
}

// MARK: - Private

private extension ExpressTokensListViewModel {
    func initialSetup() {
        runTask(in: self) { viewModel in
            let availablePairs = try await viewModel.loadAvailablePairs()
            await viewModel.updateWalletModels(availableCurrencies: availablePairs)
        }
    }

    func loadAvailablePairs() async throws -> [ExpressCurrency] {
        let currencies = walletModels.map { $0.expressCurrency }

        switch swapDirection {
        case .fromSource(let wallet):
            let pairs = try await expressAPIProvider.pairs(from: [wallet.expressCurrency], to: currencies)
            return pairs.map { $0.destination }
        case .toDestination(let wallet):
            let pairs = try await expressAPIProvider.pairs(from: currencies, to: [wallet.expressCurrency])
            return pairs.map { $0.source }
        }
    }

    @MainActor
    func updateWalletModels(availableCurrencies: [ExpressCurrency]) {
        availableWalletModels.removeAll()
        unavailableWalletModels.removeAll()

        let currenciesSet = availableCurrencies.toSet()

        walletModels
            .filter { $0 != swapDirection.wallet }
            .forEach { walletModel in
                let isAvailable = currenciesSet.contains(walletModel.expressCurrency)
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
            .removeDuplicates()
            .dropFirst()
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
        availableTokens = availableWalletModels
            .filter { searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()) }
            .map { walletModel in
                mapToExpressTokenItemViewModel(walletModel: walletModel, isDisable: false)
            }

        unavailableTokens = unavailableWalletModels
            .filter { searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()) }
            .map { walletModel in
                mapToExpressTokenItemViewModel(walletModel: walletModel, isDisable: true)
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
        switch swapDirection {
        case .fromSource:
            // [REDACTED_TODO_COMMENT]
            // expressInteractor.update(destination: walletModel)
            break
        case .toDestination:
            // [REDACTED_TODO_COMMENT]
            // expressInteractor.update(source: walletModel)
            break
        }

        coordinator.closeExpressTokensList()
    }
}

extension ExpressTokensListViewModel {
    enum SwapDirection {
        case fromSource(WalletModel)
        case toDestination(WalletModel)

        var name: String {
            switch self {
            case .fromSource(let walletModel):
                return walletModel.name
            case .toDestination(let walletModel):
                return walletModel.name
            }
        }

        var wallet: WalletModel {
            switch self {
            case .fromSource(let walletModel):
                return walletModel
            case .toDestination(let walletModel):
                return walletModel
            }
        }
    }
}

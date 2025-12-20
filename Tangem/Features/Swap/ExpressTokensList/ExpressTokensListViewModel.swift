//
//  ExpressTokensListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import SwiftUI
import TangemExpress
import TangemFoundation

final class ExpressTokensListViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var searchText: String = ""
    @Published var viewState: ViewState = .idle

    var unavailableSectionHeader: String {
        Localization.exchangeTokensUnavailableTokensHeader(swapDirection.name)
    }

    // MARK: - Dependencies

    private let swapDirection: SwapDirection
    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let expressPairsRepository: ExpressPairsRepository
    private let expressInteractor: ExpressInteractor
    private let userWalletInfo: UserWalletInfo
    private weak var coordinator: ExpressTokensListRoutable?

    // MARK: - Internal

    private var availableWalletModels: [any WalletModel] = []
    private var unavailableWalletModels: [any WalletModel] = []
    private var bag: Set<AnyCancellable> = []

    // For Analytics
    private var selectedWallet: (any WalletModel)?
    private var updateTask: Task<Void, Never>?

    init(
        swapDirection: SwapDirection,
        expressTokensListAdapter: ExpressTokensListAdapter,
        expressPairsRepository: ExpressPairsRepository,
        expressInteractor: ExpressInteractor,
        coordinator: ExpressTokensListRoutable,
        userWalletInfo: UserWalletInfo
    ) {
        self.swapDirection = swapDirection
        self.expressTokensListAdapter = expressTokensListAdapter
        self.expressPairsRepository = expressPairsRepository
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator
        self.userWalletInfo = userWalletInfo

        bind()
    }

    func onDisappear() {
        if let wallet = selectedWallet {
            Analytics.log(
                event: .swapChooseTokenScreenResult,
                params: [
                    .tokenChosen: Analytics.ParameterValue.yes.rawValue,
                    .token: wallet.tokenItem.currencySymbol,
                ]
            )
        } else {
            Analytics.log(
                event: .swapChooseTokenScreenResult,
                params: [
                    .tokenChosen: Analytics.ParameterValue.no.rawValue,
                ]
            )
        }
    }
}

// MARK: - Private

private extension ExpressTokensListViewModel {
    func bind() {
        expressTokensListAdapter.walletModels()
            .withWeakCaptureOf(self)
            .sink { viewModel, walletModels in
                viewModel.updateAvailablePairs(walletModels: walletModels)
            }
            .store(in: &bag)

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

    func updateAvailablePairs(walletModels: [any WalletModel]) {
        updateTask?.cancel()
        updateTask = runTask(in: self) { viewModel in
            let availablePairs = await viewModel.loadAvailablePairs()
            await viewModel.updateWalletModels(
                walletModels: walletModels,
                availableCurrencies: availablePairs
            )
        }
    }

    func loadAvailablePairs() async -> [ExpressCurrency] {
        switch swapDirection {
        case .fromSource(let tokenItem):
            let pairs = await expressPairsRepository.getPairs(from: tokenItem.expressCurrency)
            return pairs.map { $0.destination }
        case .toDestination(let tokenItem):
            let pairs = await expressPairsRepository.getPairs(to: tokenItem.expressCurrency)
            return pairs.map { $0.source }
        }
    }

    @MainActor
    func updateWalletModels(walletModels: [any WalletModel], availableCurrencies: [ExpressCurrency]) {
        availableWalletModels.removeAll()
        unavailableWalletModels.removeAll()

        let availableCurrenciesSet = availableCurrencies.toSet()
        Analytics.log(.swapChooseTokenScreenOpened, params: [.availableTokens: availableCurrencies.isEmpty ? .no : .yes])

        walletModels
            .forEach { walletModel in
                guard walletModel.id != .init(tokenItem: swapDirection.tokenItem) else { return }
                let availabilityProvider = TokenActionAvailabilityProvider(
                    userWalletConfig: userWalletInfo.config,
                    walletModel: walletModel
                )
                let isAvailable = availableCurrenciesSet.contains(walletModel.tokenItem.expressCurrency.asCurrency)
                let isSwapAvailable = availabilityProvider.isSwapAvailable

                if isAvailable, isSwapAvailable {
                    availableWalletModels.append(walletModel)
                } else {
                    unavailableWalletModels.append(walletModel)
                }
            }

        updateView()
    }

    func updateView(searchText: String = "") {
        let availableTokens = availableWalletModels
            .filter { filter(searchText, item: $0.tokenItem) }
            .map { walletModel in
                mapToExpressTokenItemViewModel(walletModel: walletModel, isDisable: false)
            }

        let unavailableTokens = unavailableWalletModels
            .filter { filter(searchText, item: $0.tokenItem) }
            .map { walletModel in
                mapToExpressTokenItemViewModel(walletModel: walletModel, isDisable: true)
            }

        if searchText.isEmpty, availableTokens.isEmpty, unavailableTokens.isEmpty {
            viewState = .isEmpty
        } else {
            viewState = .loaded(availableTokens: availableTokens, unavailableTokens: unavailableTokens)
        }
    }

    func filter(_ text: String, item: TokenItem) -> Bool {
        if text.isEmpty {
            return true
        }

        let isContainsName = item.name.lowercased().contains(text.lowercased())
        let isContainsCurrencySymbol = item.currencySymbol.lowercased().contains(text.lowercased())

        return isContainsName || isContainsCurrencySymbol
    }

    func mapToExpressTokenItemViewModel(walletModel: any WalletModel, isDisable: Bool) -> ExpressTokenItemViewModel {
        let tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
        let balance = walletModel.availableBalanceProvider.formattedBalanceType.value
        let fiatBalance = walletModel.fiatAvailableBalanceProvider.formattedBalanceType.value

        return ExpressTokenItemViewModel(
            id: walletModel.id.id,
            tokenIconInfo: tokenIconInfo,
            name: walletModel.name,
            symbol: walletModel.tokenItem.currencySymbol,
            balance: balance,
            fiatBalance: fiatBalance,
            isDisable: isDisable,
            itemDidTap: { [weak self] in
                self?.userDidTap(on: walletModel)
            }
        )
    }

    func userDidTap(on walletModel: any WalletModel) {
        let expressInteractorWallet = ExpressInteractorWalletModelWrapper(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            expressOperationType: .swap
        )

        switch swapDirection {
        case .fromSource:
            expressInteractor.update(destination: expressInteractorWallet)
        case .toDestination:
            expressInteractor.update(sender: expressInteractorWallet)
        }

        selectedWallet = walletModel
        coordinator?.closeExpressTokensList()
    }
}

extension ExpressTokensListViewModel {
    enum ViewState {
        case idle
        case loading
        case isEmpty
        case loaded(availableTokens: [ExpressTokenItemViewModel], unavailableTokens: [ExpressTokenItemViewModel])
    }

    enum SwapDirection {
        case fromSource(TokenItem)
        case toDestination(TokenItem)

        var name: String {
            switch self {
            case .fromSource(let walletModel):
                return walletModel.name
            case .toDestination(let walletModel):
                return walletModel.name
            }
        }

        var tokenItem: TokenItem {
            switch self {
            case .fromSource(let tokenItem):
                return tokenItem
            case .toDestination(let tokenItem):
                return tokenItem
            }
        }
    }
}

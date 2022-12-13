//
//  SwappingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemExchange

final class SwappingViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var sendCurrencyViewModel: SendCurrencyViewModel?
    @Published var receiveCurrencyViewModel: ReceiveCurrencyViewModel?
    @Published var isLoading: Bool = false

    @Published var sendDecimalValue: Decimal?
    @Published var refreshWarningRowViewModel: DefaultWarningRowViewModel?

    @Published var mainButtonIsEnabled: Bool = false
    @Published var mainButtonState: MainButtonState = .swap

    var informationSectionViewModels: [InformationSectionViewModel] {
        var viewModels: [InformationSectionViewModel] = [.fee(swappingFeeRowViewModel)]
        if let feeWarningRowViewModel {
            viewModels.append(.warning(feeWarningRowViewModel))
        }

        return viewModels
    }

    @Published private var swappingFeeRowViewModel = SwappingFeeRowViewModel(state: .idle)
    @Published private var feeWarningRowViewModel: DefaultWarningRowViewModel?

    // MARK: - Dependencies

    private let exchangeManager: ExchangeManager
    private let swappingDestinationService: SwappingDestinationServicing
    private let userCurrenciesProvider: UserCurrenciesProviding
    private let tokenIconURLBuilder: TokenIconURLBuilding
    private unowned let coordinator: SwappingRoutable

    // MARK: - Private

    private var bag: Set<AnyCancellable> = []

    init(
        exchangeManager: ExchangeManager,
        swappingDestinationService: SwappingDestinationServicing,
        userCurrenciesProvider: UserCurrenciesProviding,
        tokenIconURLBuilder: TokenIconURLBuilding,
        coordinator: SwappingRoutable
    ) {
        self.exchangeManager = exchangeManager
        self.swappingDestinationService = swappingDestinationService
        self.userCurrenciesProvider = userCurrenciesProvider
        self.tokenIconURLBuilder = tokenIconURLBuilder
        self.coordinator = coordinator

        setupView()
        bind()
        exchangeManager.setDelegate(self)
        loadDestinationIfNeeded()
    }

    func userDidRequestChangeDestination(to currency: Currency) {
        var items = exchangeManager.getExchangeItems()
        items.destination = currency

        exchangeManager.update(exchangeItems: items)
    }

    func userDidTapSwapExchangeItemsButton() {
        var items = exchangeManager.getExchangeItems()

        guard let destination = items.destination else {
            return
        }

        let source = items.source

        items.source = destination
        items.destination = source

        exchangeManager.update(exchangeItems: items)
    }

    func userDidTapChangeDestinationButton() {
        openTokenListView()
    }

    func userDidTapMainButton() {
        // [REDACTED_TODO_COMMENT]
    }

    func loadDestinationIfNeeded() {
        guard exchangeManager.getExchangeItems().destination == nil else {
            print("Exchange item destination has already set")
            return
        }

        Task {
            var items = exchangeManager.getExchangeItems()

            do {
                items.destination = try await swappingDestinationService.getDestination(source: items.source)
                exchangeManager.update(exchangeItems: items)
            } catch {
                print("Destination load handle error", error)
                items.destination = nil
            }
        }
    }
}

// MARK: - Navigation

private extension SwappingViewModel {
    func openTokenListView() {
        let source = exchangeManager.getExchangeItems().source
        let userCurrencies = userCurrenciesProvider.getCurrencies(
            blockchain: source.blockchain
        )

        coordinator.presentSwappingTokenList(
            sourceCurrency: source,
            userCurrencies: userCurrencies
        )
    }

    func openSuccessView() {
        coordinator.presentSuccessView(fromCurrency: "ETH", toCurrency: "USDT")
    }

    func openPermissionView() {
        let inputModel = SwappingPermissionViewModel.InputModel(
            smartContractNetworkName: "DAI",
            amount: 1000,
            yourWalletAddress: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
            spenderWalletAddress: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
            fee: 2.14
        )
        coordinator.presentPermissionView(inputModel: inputModel)
    }
}

// MARK: - ExchangeManagerDelegate

extension SwappingViewModel: ExchangeManagerDelegate {
    func exchangeManager(_ manager: ExchangeManager, didUpdate exchangeItems: ExchangeItems) {
        DispatchQueue.main.async {
            self.updateView(exchangeItems: exchangeItems)
        }
    }

    func exchangeManager(_ manager: ExchangeManager, didUpdate availabilityState: ExchangeAvailabilityState) {
        DispatchQueue.main.async {
            self.updateState(state: availabilityState)
        }
    }

    func exchangeManager(_ manager: ExchangeManager, didUpdate availabilityForExchange: Bool) {
        DispatchQueue.main.async {
            self.mainButtonState = availabilityForExchange ? .swap : .givePermission
            self.sendCurrencyViewModel?.update(isLockedVisible: !availabilityForExchange)
        }
    }
}

// MARK: - View updates

private extension SwappingViewModel {
    func updateView(exchangeItems: ExchangeItems) {
        let source = exchangeItems.source
        let destination = exchangeItems.destination

        sendCurrencyViewModel = SendCurrencyViewModel(
            balance: exchangeItems.sourceBalance.balance,
            maximumFractionDigits: source.decimalCount,
            fiatValue: exchangeItems.sourceBalance.fiatBalance,
            isLockedVisible: !exchangeManager.isAvailableForExchange(),
            tokenIcon: mapToSwappingTokenIconViewModel(currency: source)
        )

        let state: ReceiveCurrencyViewModel.State

        switch exchangeManager.getAvailabilityState() {
        case .idle, .requiredRefresh:
            state = .loaded(0, fiatValue: 0)
        case .loading:
            state = .loading
        case let .preview(result),
             let .available(result, _),
             let .requiredPermission(result, _):
            state = .loaded(result.expectedAmount, fiatValue: result.expectedFiatAmount)
        }

        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            state: state,
            tokenIcon: mapToSwappingTokenIconViewModel(currency: destination)
        )
    }

    func updateState(state: ExchangeAvailabilityState) {
        updateFeeValue(state: state)
        updateMainButton(state: state)

        switch state {
        case .idle:
            refreshWarningRowViewModel = nil
            feeWarningRowViewModel = nil
            receiveCurrencyViewModel?.updateState(.loaded(0, fiatValue: 0))

        case .loading:
            feeWarningRowViewModel = nil
            refreshWarningRowViewModel?.update(detailsType: .loader)
            receiveCurrencyViewModel?.updateState(.loading)

        case let .preview(result),
             let .available(result, _),
             let .requiredPermission(result, _):
            refreshWarningRowViewModel = nil
            feeWarningRowViewModel = nil
            receiveCurrencyViewModel?.updateState(
                .loaded(result.expectedAmount, fiatValue: result.expectedFiatAmount)
            )

        case .requiredRefresh(let error):
            receiveCurrencyViewModel?.updateState(.loaded(0, fiatValue: 0))
            refreshWarningRowViewModel = DefaultWarningRowViewModel(
                icon: Assets.attention,
                title: "Exchange rate has expired", // [REDACTED_TODO_COMMENT]
                subtitle: error.localizedDescription, // [REDACTED_TODO_COMMENT]
                detailsType: .icon(Assets.refreshWarningIcon),
                action: { [weak self] in
                    self?.exchangeManager.refresh()
                }
            )
        }
    }

    func updateFeeValue(state: ExchangeAvailabilityState) {
        switch state {
        case .idle, .requiredRefresh:
            swappingFeeRowViewModel.update(state: .idle)
        case .loading:
            swappingFeeRowViewModel.update(state: .loading)
        case let .preview(result),
             let .available(result, _),
             let .requiredPermission(result, _):
            swappingFeeRowViewModel.update(
                state: .fee(
                    fee: result.fee.groupedFormatted(maximumFractionDigits: result.decimalCount),
                    symbol: exchangeManager.getExchangeItems().source.symbol,
                    fiat: result.fiatFee.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
                )
            )
        }
    }

    func updateMainButton(state: ExchangeAvailabilityState) {
        switch state {
        case .idle:
            mainButtonIsEnabled = false
            mainButtonState = .swap
        case .loading, .requiredRefresh:
            mainButtonIsEnabled = false

        case let .preview(result),
             let .available(result, _),
             let .requiredPermission(result, _):
            mainButtonIsEnabled = result.isEnoughAmountForExchange

            if result.isEnoughAmountForExchange {
                mainButtonState = .givePermission
            } else {
                mainButtonState = .insufficientFunds
            }
        }
    }

    func setupView() {
        updateState(state: .idle)
        updateView(exchangeItems: exchangeManager.getExchangeItems())
    }

    func bind() {
        $sendDecimalValue
            .removeDuplicates()
            .dropFirst()
            .debounce(for: 1, scheduler: DispatchQueue.global())
            .sink { [weak self] amount in
                self?.exchangeManager.update(amount: amount)
            }
            .store(in: &bag)
    }

    func mapToSwappingTokenIconViewModel(currency: Currency?) -> SwappingTokenIconViewModel {
        guard let currency = currency else {
            return SwappingTokenIconViewModel(state: .loading)
        }

        switch currency.currencyType {
        case .coin:
            return SwappingTokenIconViewModel(
                state: .loaded(
                    imageURL: tokenIconURLBuilder.iconURL(id: currency.blockchain.id, size: .large),
                    symbol: currency.symbol
                )
            )
        case .token:
            return SwappingTokenIconViewModel(
                state: .loaded(
                    imageURL: tokenIconURLBuilder.iconURL(id: currency.id, size: .large),
                    networkURL: tokenIconURLBuilder.iconURL(id: currency.blockchain.id, size: .small),
                    symbol: currency.symbol
                )
            )
        }
    }
}

extension SwappingViewModel {
    enum InformationSectionViewModel: Hashable, Identifiable {
        var id: Int { hashValue }

        case fee(SwappingFeeRowViewModel)
        case warning(DefaultWarningRowViewModel)
    }

    enum MainButtonState: Hashable, Identifiable {
        var id: Int { hashValue }

        case swap
        case insufficientFunds
        case givePermission
        case permitAndSwap

        var title: String {
            switch self {
            case .swap:
                return "swapping_swap".localized
            case .insufficientFunds:
                return "swapping_insufficient_funds".localized
            case .givePermission:
                return "swapping_give_permission".localized
            case .permitAndSwap:
                return "swapping_permit_and_swap".localized
            }
        }

        var icon: MainButton.Icon? {
            switch self {
            case .swap, .permitAndSwap:
                return .trailing(Assets.tangemIcon)
            case .givePermission, .insufficientFunds:
                return .none
            }
        }
    }
}

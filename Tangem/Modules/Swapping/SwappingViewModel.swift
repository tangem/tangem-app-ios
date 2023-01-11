//
//  SwappingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemExchange
import TangemSdk

final class SwappingViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var sendCurrencyViewModel: SendCurrencyViewModel?
    @Published var receiveCurrencyViewModel: ReceiveCurrencyViewModel?
    @Published var isLoading: Bool = false

    @Published var sendDecimalValue: Decimal?
    @Published var refreshWarningRowViewModel: DefaultWarningRowViewModel?

    @Published var mainButtonIsEnabled: Bool = false
    @Published var mainButtonState: MainButtonState = .swap
    @Published var errorAlert: AlertBinder?

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
    private let transactionSender: TransactionSendable
    private unowned let coordinator: SwappingRoutable

    // MARK: - Private

    private var bag: Set<AnyCancellable> = []

    init(
        exchangeManager: ExchangeManager,
        swappingDestinationService: SwappingDestinationServicing,
        userCurrenciesProvider: UserCurrenciesProviding,
        tokenIconURLBuilder: TokenIconURLBuilding,
        transactionSender: TransactionSendable,
        coordinator: SwappingRoutable
    ) {
        self.exchangeManager = exchangeManager
        self.swappingDestinationService = swappingDestinationService
        self.userCurrenciesProvider = userCurrenciesProvider
        self.tokenIconURLBuilder = tokenIconURLBuilder
        self.transactionSender = transactionSender
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

    func didTapMainButton() {
        switch mainButtonState {
        case .permitAndSwap:
            break // [REDACTED_TODO_COMMENT]
        case .swap:
            swapItems()
        case .givePermission:
            openPermissionView()
        case .insufficientFunds:
            assertionFailure("Button should be disabled")
            break
        }
    }

    func didSendApproveTransaction() {
        exchangeManager.refresh()
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

    func openSuccessView(
        result: SwappingResultDataModel,
        transactionModel: ExchangeTransactionDataModel
    ) {
        let amount = transactionModel.sourceCurrency.convertFromWEI(value: transactionModel.amount)
        let source = CurrencyAmount(
            value: amount,
            currency: transactionModel.sourceCurrency
        )

        let result = CurrencyAmount(
            value: result.amount,
            currency: transactionModel.destinationCurrency
        )

        coordinator.presentSuccessView(source: source, result: result)
    }

    func openPermissionView() {
        let state = exchangeManager.getAvailabilityState()
        guard case let .available(result, info) = state,
              result.isPermissionRequired else {
            return
        }

        coordinator.presentPermissionView(
            transactionInfo: info,
            transactionSender: transactionSender
        )
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

    func exchangeManager(_ manager: ExchangeManager, didUpdate isEnoughAllowance: Bool) {
        DispatchQueue.main.async {
            self.sendCurrencyViewModel?.update(isLockedVisible: !isEnoughAllowance)
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
            isLockedVisible: !exchangeManager.isEnoughAllowance(),
            tokenIcon: mapToSwappingTokenIconViewModel(currency: source)
        )

        let state: ReceiveCurrencyViewModel.State

        switch exchangeManager.getAvailabilityState() {
        case .idle, .requiredRefresh:
            state = .loaded(0, fiatValue: 0)
        case .loading:
            state = .loading
        case let .preview(result):
            state = .loaded(result.expectedAmount, fiatValue: result.expectedFiatAmount)
        case let .available(result, _):
            state = .loaded(result.amount, fiatValue: result.amount)
        }

        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            balance: exchangeItems.destinationBalance,
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

        case let .preview(result):
            refreshWarningRowViewModel = nil
            feeWarningRowViewModel = nil
            receiveCurrencyViewModel?.updateState(
                .loaded(result.expectedAmount, fiatValue: result.expectedFiatAmount)
            )

        case let .available(result, _):
            refreshWarningRowViewModel = nil
            receiveCurrencyViewModel?.updateState(
                .loaded(result.amount, fiatValue: result.fiatAmount)
            )

            if result.isEnoughAmountForFee {
                feeWarningRowViewModel = nil
            } else {
                let sourceBlockchain = exchangeManager.getExchangeItems().source.blockchain
                feeWarningRowViewModel = DefaultWarningRowViewModel(
                    icon: Assets.attention,
                    title: nil,
                    subtitle: Localization.swappingNotEnoughFundsForFee(sourceBlockchain.symbol, sourceBlockchain.symbol)
                )
            }

        case .requiredRefresh(let error):
            receiveCurrencyViewModel?.updateState(.loaded(0, fiatValue: 0))
            processingError(error: error)
        }
    }

    func updateFeeValue(state: ExchangeAvailabilityState) {
        switch state {
        case .idle, .requiredRefresh, .preview:
            swappingFeeRowViewModel.update(state: .idle)
        case .loading:
            swappingFeeRowViewModel.update(state: .loading)
        case let .available(result, _):
            let source = exchangeManager.getExchangeItems().source

            let fee = result.fee.rounded(scale: 2, roundingMode: .up)
            swappingFeeRowViewModel.update(
                state: .fee(
                    fee: fee.groupedFormatted(maximumFractionDigits: source.decimalCount),
                    symbol: source.blockchain.symbol,
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
        case let .preview(model):
            mainButtonIsEnabled = model.isEnoughAmountForExchange

            if !model.isEnoughAmountForExchange {
                mainButtonState = .insufficientFunds
            } else if model.isPermissionRequired {
                mainButtonState = .givePermission
            } else {
                mainButtonState = .swap
            }

        case let .available(model, _):
            mainButtonIsEnabled = model.isEnoughAmountForExchange && model.isEnoughAmountForFee

            if !model.isEnoughAmountForExchange {
                mainButtonState = .insufficientFunds
            } else if model.isPermissionRequired {
                mainButtonState = .givePermission
            } else {
                mainButtonState = .swap
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

    func loadDestinationIfNeeded() {
        guard exchangeManager.getExchangeItems().destination == nil else {
            AppLog.shared.debug("Exchange item destination has already set")
            return
        }

        Task {
            var items = exchangeManager.getExchangeItems()

            do {
                items.destination = try await swappingDestinationService.getDestination(source: items.source)
                exchangeManager.update(exchangeItems: items)
            } catch {
                AppLog.shared.debug("Destination load handle error")
                AppLog.shared.error(error)
                items.destination = nil
            }
        }
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

    func swapItems() {
        let state = exchangeManager.getAvailabilityState()
        guard case let .available(result, info) = state else {
            return
        }

        Task {
            do {
                try await transactionSender.sendTransaction(info)
                openSuccessView(result: result, transactionModel: info)
            } catch TangemSdkError.userCancelled {
                // Do nothing
            } catch {
                errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
            }
        }
    }

    func processingError(error: Error) {
        switch error {
        case let error as ExchangeManagerError:
            switch error {
            case .walletAddressNotFound, .destinationNotFound, .amountNotFound:
                updateRefreshWarningRowViewModel(message: error.localizedDescription)
            }
        case let error as ExchangeProviderError:
            switch error {
            case let .requestError(error):
                updateRefreshWarningRowViewModel(message: error.detailedError.localizedDescription)
            case let .oneInchError(error):
                updateRefreshWarningRowViewModel(message: error.description)
            case let .decodingError(error):
                updateRefreshWarningRowViewModel(message: error.localizedDescription)
            }
        default:
            updateRefreshWarningRowViewModel(message: Localization.commonError)
        }
    }

    func updateRefreshWarningRowViewModel(title: String? = nil, message: String) {
        refreshWarningRowViewModel = DefaultWarningRowViewModel(
            icon: Assets.attention,
            title: title,
            subtitle: message,
            detailsType: .icon(Assets.refreshWarningIcon),
            action: { [weak self] in
                self?.exchangeManager.refresh()
            }
        )
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
                return Localization.swappingSwap
            case .insufficientFunds:
                return Localization.swappingInsufficientFunds
            case .givePermission:
                return Localization.swappingGivePermission
            case .permitAndSwap:
                return Localization.swappingPermitAndSwap
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

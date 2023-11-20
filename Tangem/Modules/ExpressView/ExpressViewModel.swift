//
//  ExpressViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemSwapping
import UIKit
import enum TangemSdk.TangemSdkError

final class ExpressViewModel: ObservableObject {
    // MARK: - ViewState

    // Main bubbles
    @Published var sendCurrencyViewModel: SendCurrencyViewModel?
    @Published var sendDecimalValue: DecimalNumberTextField.DecimalValue?
    @Published var swapButtonIsLoading: Bool = false
    @Published var receiveCurrencyViewModel: ReceiveCurrencyViewModel?

    // Warnings
    @Published var refreshWarningRowViewModel: DefaultWarningRowViewModel?
    @Published var highPriceImpactWarningRowViewModel: DefaultWarningRowViewModel?
    @Published var pendingTransaction: DefaultWarningRowViewModel?
    @Published var permissionInfoRowViewModel: DefaultWarningRowViewModel?
    @Published var feeWarningRowViewModel: DefaultWarningRowViewModel?

    // Provider
    @Published var providerState: ProviderState?

    // Fee
    @Published var expressFeeRowViewModel: ExpressFeeRowData?

    // Main button
    @Published var mainButtonIsEnabled: Bool = false
    @Published var mainButtonState: MainButtonState = .swap
    @Published var errorAlert: AlertBinder?

    // [REDACTED_TODO_COMMENT]
    var informationSectionViewModels: [DefaultWarningRowViewModel] {
        [
            refreshWarningRowViewModel,
            highPriceImpactWarningRowViewModel,
            pendingTransaction,
            permissionInfoRowViewModel,
            feeWarningRowViewModel,
        ].compactMap { $0 }
    }

    // MARK: - Dependencies

    private let initialWallet: WalletModel
    private let swappingFeeFormatter: SwappingFeeFormatter
    private let balanceConverter: BalanceConverter
    private let balanceFormatter: BalanceFormatter
    private let expressProviderFormatter: ExpressProviderFormatter

    private unowned let swappingInteractor: ExpressInteractor
    private unowned let coordinator: ExpressRoutable

    // MARK: - Private

    private lazy var refreshDataTimer = Timer.publish(every: 10, on: .main, in: .common)
    private var refreshDataTimerBag: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        initialWallet: WalletModel,
        swappingFeeFormatter: SwappingFeeFormatter,
        balanceConverter: BalanceConverter,
        balanceFormatter: BalanceFormatter,
        expressProviderFormatter: ExpressProviderFormatter,
        swappingInteractor: ExpressInteractor,
        coordinator: ExpressRoutable
    ) {
        self.initialWallet = initialWallet
        self.swappingFeeFormatter = swappingFeeFormatter
        self.balanceConverter = balanceConverter
        self.balanceFormatter = balanceFormatter
        self.expressProviderFormatter = expressProviderFormatter
        self.swappingInteractor = swappingInteractor
        self.coordinator = coordinator

        Analytics.log(event: .swapScreenOpenedSwap, params: [.token: initialWallet.tokenItem.currencySymbol])
        setupView()
        bind()
    }

    func userDidTapMaxAmount() {
        guard let sourceBalance = swappingInteractor.getSender().balanceValue else {
            return
        }

        sendDecimalValue = .external(sourceBalance)
        updateSendFiatValue(amount: sourceBalance)
        swappingInteractor.update(amount: sourceBalance)
    }

    func userDidTapSwapSwappingItemsButton() {
        Analytics.log(.swapButtonSwipe)
        update(restriction: .none)
        swappingInteractor.swapPair()

        // If we have amount then we should round and update it with new decimalCount
        guard let amount = sendDecimalValue?.value else {
            return
        }

        let source = swappingInteractor.getSender()
        let roundedAmount = amount.rounded(scale: source.decimalCount, roundingMode: .down)
        sendDecimalValue = .external(roundedAmount)
        updateSendFiatValue(amount: roundedAmount)
        swappingInteractor.update(amount: roundedAmount)
    }

    func userDidTapChangeSourceButton() {
        coordinator.presentSwappingTokenList(swapDirection: .toDestination(initialWallet))
    }

    func userDidTapChangeDestinationButton() {
        coordinator.presentSwappingTokenList(swapDirection: .fromSource(initialWallet))
    }

    func didTapMainButton() {
        switch mainButtonState {
        case .permitAndSwap:
            Analytics.log(.swapButtonPermitAndSwap)
        // [REDACTED_TODO_COMMENT]
        case .swap:
            sendTransaction()
        case .givePermission:
            Analytics.log(.swapButtonGivePermission)
            openApproveView()
        case .insufficientFunds:
            assertionFailure("Button should be disabled")
        }
    }

    func didCloseApproveSheet() {
        restartTimer()
    }

    func didTapWaringRefresh() {
        swappingInteractor.refresh(type: .full)
    }

    // Workaround iOS 17 a sheet memory leak
    // https://developer.apple.com/forums/thread/738840
    func onDisappear() {
        stopTimer()
    }
}

// MARK: - Navigation

private extension ExpressViewModel {
    @MainActor
    func openSuccessView(resultState: ExpressInteractor.TransactionSendResultState) {
        // [REDACTED_TODO_COMMENT]
    }

    func openApproveView() {
        guard case .restriction(let type, _) = swappingInteractor.getState(),
              case .permissionRequired = type else {
            return
        }

        stopTimer()
        coordinator.presentApproveView()
    }

    func presentProviderSelectorView() {
        runTask(in: self) { viewModel in
            async let quotes = viewModel.swappingInteractor.getAllQuotes()
            async let provider = viewModel.swappingInteractor.getSelectedProvider()

            let input = await ExpressProvidersBottomSheetViewModel.InputModel(
                selectedProviderId: provider?.id,
                quotes: quotes
            )

            await runOnMain {
                viewModel.coordinator.presentProviderSelectorView(input: input)
            }
        }
    }
}

// MARK: - View updates

private extension ExpressViewModel {
    func setupView() {
        updateState(state: .idle)

        sendCurrencyViewModel = SendCurrencyViewModel(
            maximumFractionDigits: swappingInteractor.getSender().decimalCount,
            canChangeCurrency: swappingInteractor.getSender().id != initialWallet.id,
            tokenIconState: .loading
        )

        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            canChangeCurrency: swappingInteractor.getDestination()?.id != initialWallet.id,
            tokenIconState: .loading
        )

        updateSendView(wallet: swappingInteractor.getSender())
        updateReceiveView(wallet: swappingInteractor.getDestination())
    }

    func bind() {
        $sendDecimalValue
            .removeDuplicates { $0?.value == $1?.value }
            // We skip the first nil value from the text field
            .dropFirst()
            // If value == nil then continue chain to reset states to idle
            .filter { $0?.isInternal ?? true }
            .handleEvents(receiveOutput: { [weak self] amount in
                self?.swappingInteractor.cancelRefresh()
                self?.updateSendFiatValue(amount: amount?.value)
                self?.stopTimer()
            })
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .sink { [weak self] amount in
                // Remove refresh warning if user start typing
                self?.updateRefreshWarningRowViewModel(message: .none)
                self?.swappingInteractor.update(amount: amount?.value)

                if let amount, amount.value > 0 {
                    self?.startTimer()
                }
            }
            .store(in: &bag)

        swappingInteractor.state
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateState(state: state)
            }
            .store(in: &bag)

        swappingInteractor.swappingPair
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pair in
                self?.updateSendView(wallet: pair.sender)
                self?.updateReceiveView(wallet: pair.destination)
            }
            .store(in: &bag)
    }

    // MARK: - Update main bubbles

    func updateSendView(wallet: WalletModel) {
        sendCurrencyViewModel?.balance = .formatted(wallet.balance)
        sendCurrencyViewModel?.maximumFractionDigits = wallet.decimalCount
        sendCurrencyViewModel?.canChangeCurrency = wallet.id != initialWallet.id
        sendCurrencyViewModel?.tokenIconState = mapToSwappingTokenIconViewModelState(wallet: wallet)

        updateSendFiatValue(amount: sendDecimalValue?.value)
    }

    func updateSendFiatValue(amount: Decimal?) {
        guard let amount = amount else {
            let formatted = balanceFormatter.formatFiatBalance(0)
            sendCurrencyViewModel?.update(fiatValue: .formatted(formatted))
            return
        }

        let tokenItem = swappingInteractor.getSender().tokenItem

        guard let currencyId = tokenItem.currencyId else {
            sendCurrencyViewModel?.update(fiatValue: .formatted("-"))
            return
        }

        if let fiatValue = balanceConverter.convertToFiat(value: amount, from: currencyId) {
            let formatted = balanceFormatter.formatFiatBalance(fiatValue)
            sendCurrencyViewModel?.update(fiatValue: .formatted(formatted))
            return
        }

        sendCurrencyViewModel?.update(fiatValue: .loading)

        runTask(in: self) { [currencyId] viewModel in
            let fiatValue = try await viewModel.balanceConverter.convertToFiat(value: amount, from: currencyId)
            let formatted = viewModel.balanceFormatter.formatFiatBalance(fiatValue)
            try Task.checkCancellation()

            await runOnMain {
                viewModel.sendCurrencyViewModel?.update(fiatValue: .formatted(formatted))
            }
        }
    }

    func updateReceiveView(wallet: WalletModel?) {
        receiveCurrencyViewModel?.balance = wallet?.balance ?? ""
        receiveCurrencyViewModel?.canChangeCurrency = wallet?.id != initialWallet.id
        receiveCurrencyViewModel?.tokenIconState = mapToSwappingTokenIconViewModelState(wallet: wallet)

        let state = swappingInteractor.getState()
        switch state {
        case .loading:
            receiveCurrencyViewModel?.update(cryptoAmountState: .loading)
            receiveCurrencyViewModel?.update(fiatAmountState: .loading)
        default:
            updateReceiveCurrencyValue(expectAmount: state.quote?.quote?.expectAmount)
        }
    }

    func updateReceiveCurrencyValue(expectAmount: Decimal?) {
        guard let expectAmount else {
            receiveCurrencyViewModel?.update(cryptoAmountState: .loaded(0))
            let formatted = balanceFormatter.formatFiatBalance(0)

            receiveCurrencyViewModel?.update(fiatAmountState: .formatted(formatted))
            return
        }

        receiveCurrencyViewModel?.update(cryptoAmountState: .loaded(expectAmount))

        let tokenItem = swappingInteractor.getDestination()?.tokenItem
        guard let currencyId = tokenItem?.currencyId else {
            receiveCurrencyViewModel?.update(fiatAmountState: .formatted("-"))
            return
        }

        if let fiatValue = balanceConverter.convertToFiat(value: expectAmount, from: currencyId) {
            let formatted = balanceFormatter.formatFiatBalance(fiatValue)
            receiveCurrencyViewModel?.update(fiatAmountState: .formatted(formatted))
            return
        }

        receiveCurrencyViewModel?.update(fiatAmountState: .loading)

        runTask(in: self) { [currencyId] viewModel in
            let fiatValue = try await viewModel.balanceConverter.convertToFiat(value: expectAmount, from: currencyId)
            let formatted = viewModel.balanceFormatter.formatFiatBalance(fiatValue)
            try Task.checkCancellation()

            await runOnMain {
                viewModel.receiveCurrencyViewModel?.update(fiatAmountState: .formatted(formatted))
            }
        }
    }

    // MARK: - Update for state

    func updateState(state: ExpressInteractor.ExpressInteractorState) {
        updateFeeValue(state: state)
        updateProviderView(state: state)

        // The HighPriceImpact warning can't be a restriction
        // because it can be visible even on readyToSwap state
        updateHighPriceImpact(state: state)
        updateMainButton(state: state)

        switch state {
        case .idle:
            swapButtonIsLoading = false
            update(restriction: .none)
            stopTimer()

            updateReceiveCurrencyValue(expectAmount: 0)

        case .loading(let type):
            swapButtonIsLoading = true

            // Turn on skeletons only for full update
            guard type == .full else { return }

            refreshWarningRowViewModel?.update(rightView: .loader)
            receiveCurrencyViewModel?.update(cryptoAmountState: .loading)
            receiveCurrencyViewModel?.update(fiatAmountState: .loading)

        case .restriction(let type, let quote):
            swapButtonIsLoading = false
            update(restriction: type)

            if case .requiredRefresh = type {
                stopTimer()
            } else {
                restartTimer()
            }

            updateReceiveCurrencyValue(expectAmount: quote?.quote?.expectAmount)

        case .readyToSwap(_, let quote):
            swapButtonIsLoading = false
            update(restriction: .none)
            restartTimer()

            updateReceiveCurrencyValue(expectAmount: quote.quote?.expectAmount)
        }
    }

    func updateProviderView(state: ExpressInteractor.ExpressInteractorState) {
        switch state {
        case .idle:
            providerState = .none
        case .loading(let type):
            if type == .full {
                providerState = .loading
            }
        case .restriction(_, let quote):
            if let quote {
                let data = mapToProviderRowViewModel(expectedQuote: quote)
                providerState = .loaded(data: data)
            } else {
                providerState = .none
            }

        case .readyToSwap(_, let quote):
            providerState = .loaded(data: mapToProviderRowViewModel(expectedQuote: quote))
        }
    }

    func updateFeeValue(state: ExpressInteractor.ExpressInteractorState) {
        switch state {
        case .idle, .restriction:
            expressFeeRowViewModel = nil
        case .loading(let type):
            if type == .full {
                expressFeeRowViewModel = nil
            }
        case .readyToSwap(let state, _):
            guard let fee = state.fees[swappingInteractor.getFeeOption()]?.amount.value else {
                expressFeeRowViewModel = nil
                return
            }

            let tokenItem = swappingInteractor.getSender().tokenItem
            let formattedFee = swappingFeeFormatter.format(
                fee: fee,
                currencySymbol: tokenItem.currencySymbol,
                currencyId: tokenItem.currencyId ?? ""
            )

            expressFeeRowViewModel = ExpressFeeRowData(title: Localization.sendFeeLabel, subtitle: formattedFee) { [weak self] in
                self?.coordinator.presentFeeSelectorView()
            }
        }
    }

    func updateMainButton(state: ExpressInteractor.ExpressInteractorState) {
        switch state {
        case .idle:
            mainButtonState = .swap
            mainButtonIsEnabled = false
        case .loading(let type):
            if type == .full {
                mainButtonIsEnabled = false
            }
        case .restriction(let type, _):
            switch type {
            case .permissionRequired:
                mainButtonState = .givePermission
                mainButtonIsEnabled = true

            case .hasPendingTransaction, .requiredRefresh:
                mainButtonState = .swap
                mainButtonIsEnabled = false

            case .notEnoughAmountForFee, .notEnoughAmountForSwapping, .notEnoughBalanceForSwapping:
                mainButtonState = .insufficientFunds
                mainButtonIsEnabled = false
            }

        case .readyToSwap:
            mainButtonState = .swap
            mainButtonIsEnabled = true
        }
    }

    func updateHighPriceImpact(state: ExpressInteractor.ExpressInteractorState) {
        runTask(in: self) { viewModel in
            switch state {
            case .idle:
                await runOnMain {
                    viewModel.highPriceImpactWarningRowViewModel = nil
                }
            case .loading(let type):
                if type == .full {
                    await runOnMain {
                        viewModel.highPriceImpactWarningRowViewModel = nil
                    }
                }
            case .restriction(_, let quote):
                if let quote = quote?.quote {
                    try await viewModel.checkForHighPriceImpact(
                        sourceAmount: quote.fromAmount,
                        destinationAmount: quote.expectAmount
                    )
                } else {
                    await runOnMain {
                        viewModel.highPriceImpactWarningRowViewModel = nil
                    }
                }

            case .readyToSwap(let data, _):
                try await viewModel.checkForHighPriceImpact(
                    sourceAmount: data.data.fromAmount,
                    destinationAmount: data.data.toAmount
                )
            }
        }
    }

    func checkForHighPriceImpact(sourceAmount: Decimal, destinationAmount: Decimal) async throws {
        if sourceAmount.isZero {
            // No need to calculate price impact with zero input
            await runOnMain {
                highPriceImpactWarningRowViewModel = nil
            }
            return
        }

        guard let senderCurrencyId = swappingInteractor.getSender().tokenItem.currencyId,
              let destinationCurrencyId = swappingInteractor.getDestination()?.tokenItem.currencyId else {
            throw CommonError.noData
        }

        let sourceFiatAmount = try await balanceConverter.convertToFiat(value: sourceAmount, from: senderCurrencyId)
        let destinationFiatAmount = try await balanceConverter.convertToFiat(value: destinationAmount, from: destinationCurrencyId)

        let lossesInPercents = (1 - destinationFiatAmount / sourceFiatAmount) * 100

        await runOnMain {
            let isHighPriceImpact = lossesInPercents >= Constants.highPriceImpactWarningLimit
            updateHighPriceImpact(isHighPriceImpact: isHighPriceImpact)
        }
    }
}

// MARK: - Mapping

private extension ExpressViewModel {
    func mapToMessage(error: Error) -> String {
        AppLog.shared.debug("ExpressViewModel catch error: ")
        AppLog.shared.error(error)

        switch error {
        case let error as ExpressManagerError:
            return error.localizedDescription
        case let error as ExpressInteractorError:
            return error.localizedDescription
        default:
            return error.localizedDescription
        }
    }

    func mapToSwappingTokenIconViewModelState(wallet: WalletModel?) -> SwappingTokenIconView.State {
        guard let wallet = wallet else {
            return .loading
        }

        return .icon(
            TokenIconInfoBuilder().build(from: wallet.tokenItem, isCustom: wallet.isCustom),
            symbol: wallet.tokenItem.currencySymbol
        )
    }

    func mapToProviderRowViewModel(expectedQuote: ExpectedQuote) -> ProviderRowViewModel {
        let subtitle = expressProviderFormatter.mapToRateSubtitle(
            quote: expectedQuote,
            option: .rate(
                senderCurrencyCode: swappingInteractor.getSender().tokenItem.currencySymbol,
                destinationCurrencyCode: swappingInteractor.getDestination()?.tokenItem.currencySymbol
            )
        )

        return ProviderRowViewModel(
            provider: expressProviderFormatter.mapToProvider(provider: expectedQuote.provider),
            isDisabled: false,
            badge: .none, // [REDACTED_TODO_COMMENT]
            subtitles: [subtitle],
            detailsType: .chevron
        ) { [weak self] in
            self?.presentProviderSelectorView()
        }
    }
}

// MARK: - Methods

private extension ExpressViewModel {
    func sendTransaction() {
        stopTimer()
        runTask(in: self) { root in
            do {
                let resultState = try await root.swappingInteractor.send()

                try Task.checkCancellation()

                await root.openSuccessView(resultState: resultState)

            } catch TangemSdkError.userCancelled {
                root.restartTimer()
            } catch {
                await runOnMain { [weak root] in
                    root?.errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Restrictions

private extension ExpressViewModel {
    func update(restriction: ExpressInteractor.RestrictionType?) {
        switch restriction {
        case .none:
            updateRequiredPermission(isPermissionRequired: false)
            updatePendingApprovingTransaction(hasPendingTransaction: false)
            updateEnoughAmountForFee(isNotEnoughAmountForFee: false)
            updateRefreshWarningRowViewModel(message: .none)
            updateHighPriceImpact(isHighPriceImpact: false)

        case .notEnoughAmountForSwapping:
            updateRequiredPermission(isPermissionRequired: false)
            updatePendingApprovingTransaction(hasPendingTransaction: false)
            updateEnoughAmountForFee(isNotEnoughAmountForFee: false)
            updateRefreshWarningRowViewModel(message: .none)
            updateHighPriceImpact(isHighPriceImpact: false)

        case .permissionRequired:
            updateRequiredPermission(isPermissionRequired: true)
            updatePendingApprovingTransaction(hasPendingTransaction: false)
            updateEnoughAmountForFee(isNotEnoughAmountForFee: false)
            updateRefreshWarningRowViewModel(message: .none)
            updateHighPriceImpact(isHighPriceImpact: false)

        case .hasPendingTransaction:
            updateRequiredPermission(isPermissionRequired: false)
            updatePendingApprovingTransaction(hasPendingTransaction: true)
            updateEnoughAmountForFee(isNotEnoughAmountForFee: false)
            updateRefreshWarningRowViewModel(message: .none)
            updateHighPriceImpact(isHighPriceImpact: false)

        case .notEnoughBalanceForSwapping:
            updateRequiredPermission(isPermissionRequired: false)
            updatePendingApprovingTransaction(hasPendingTransaction: false)
            updateEnoughAmountForFee(isNotEnoughAmountForFee: false)
            updateRefreshWarningRowViewModel(message: .none)
            updateHighPriceImpact(isHighPriceImpact: false)

        case .notEnoughAmountForFee:
            updateRequiredPermission(isPermissionRequired: false)
            updatePendingApprovingTransaction(hasPendingTransaction: false)
            updateEnoughAmountForFee(isNotEnoughAmountForFee: true)
            updateRefreshWarningRowViewModel(message: .none)
            updateHighPriceImpact(isHighPriceImpact: false)

        case .requiredRefresh(let error):
            updateRequiredPermission(isPermissionRequired: false)
            updatePendingApprovingTransaction(hasPendingTransaction: false)
            updateEnoughAmountForFee(isNotEnoughAmountForFee: false)
            updateRefreshWarningRowViewModel(message: mapToMessage(error: error))
            updateHighPriceImpact(isHighPriceImpact: false)
        }
    }

    func updateRequiredPermission(isPermissionRequired: Bool) {
        if isPermissionRequired {
            let symbol = swappingInteractor.getSender().tokenItem.blockchain.currencySymbol
            permissionInfoRowViewModel = DefaultWarningRowViewModel(
                title: Localization.swappingGivePermission,
                subtitle: Localization.swappingPermissionSubheader(symbol),
                leftView: .icon(Assets.swapLock)
            )
        } else {
            permissionInfoRowViewModel = nil
        }
    }

    func updatePendingApprovingTransaction(hasPendingTransaction: Bool) {
        if hasPendingTransaction {
            pendingTransaction = DefaultWarningRowViewModel(
                title: Localization.swappingPendingTransactionTitle,
                subtitle: Localization.swappingPendingTransactionSubtitle,
                leftView: .loader
            )
        } else {
            pendingTransaction = nil
        }
    }

    func updateEnoughAmountForFee(isNotEnoughAmountForFee: Bool) {
        if isNotEnoughAmountForFee {
            let symbol = swappingInteractor.getSender().tokenItem.blockchain.currencySymbol
            feeWarningRowViewModel = DefaultWarningRowViewModel(
                subtitle: Localization.swappingNotEnoughFundsForFee(symbol, symbol),
                leftView: .icon(Assets.attention)
            )
        } else {
            feeWarningRowViewModel = nil
        }
    }

    func updateRefreshWarningRowViewModel(message: String?) {
        if let message {
            refreshWarningRowViewModel = DefaultWarningRowViewModel(
                subtitle: Localization.swappingErrorWrapper(message.capitalizingFirstLetter()),
                leftView: .icon(Assets.attention),
                rightView: .icon(Assets.refreshWarningIcon)
            ) { [weak self] in
                self?.didTapWaringRefresh()
            }
        } else {
            refreshWarningRowViewModel = nil
        }
    }

    func updateHighPriceImpact(isHighPriceImpact: Bool) {
        if isHighPriceImpact {
            highPriceImpactWarningRowViewModel = DefaultWarningRowViewModel(
                title: Localization.swappingHighPriceImpact,
                subtitle: Localization.swappingHighPriceImpactDescription,
                leftView: .icon(Assets.warningIcon)
            )
        } else {
            highPriceImpactWarningRowViewModel = nil
        }
    }
}

// MARK: - Timer

private extension ExpressViewModel {
    func restartTimer() {
        stopTimer()
        startTimer()
    }

    func stopTimer() {
        AppLog.shared.debug("[Swap] Stop timer")
        refreshDataTimerBag?.cancel()
        refreshDataTimer
            .connect()
            .cancel()
    }

    func startTimer() {
        AppLog.shared.debug("[Swap] Start timer")
        refreshDataTimerBag = refreshDataTimer
            .autoconnect()
            .sink { [weak self] date in
                AppLog.shared.debug("[Swap] Timer call autoupdate")
                self?.swappingInteractor.refresh(type: .refreshRates)
            }
    }
}

extension ExpressViewModel {
    enum ProviderState: Identifiable {
        var id: Int {
            switch self {
            case .loading:
                return "loading".hashValue
            case .loaded(let data):
                return data.id
            }
        }

        case loading
        case loaded(data: ProviderRowViewModel)
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
                return Localization.swappingSwapAction
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

extension ExpressViewModel {
    private enum Constants {
        static let highPriceImpactWarningLimit: Decimal = 10
    }
}

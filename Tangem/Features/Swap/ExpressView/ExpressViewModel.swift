//
//  ExpressViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import UIKit
import TangemLocalization
import TangemExpress
import TangemAssets
import TangemFoundation
import TangemUI
import BlockchainSdk
import struct TangemUIUtils.AlertBinder
import enum TangemSdk.TangemSdkError

final class ExpressViewModel: ObservableObject {
    @Injected(\.ukGeoDefiner) private var ukGeoDefiner: UKGeoDefiner

    // MARK: - ViewState

    // Main bubbles
    @Published var sendCurrencyViewModel: SendCurrencyViewModel?
    @Published var isSwapButtonLoading: Bool = false
    @Published var isSwapButtonDisabled: Bool = false
    @Published var receiveCurrencyViewModel: ReceiveCurrencyViewModel?
    @Published var isMaxAmountButtonHidden: Bool = false

    /// Warnings
    @Published var notificationInputs: [NotificationViewInput] = []

    /// Provider
    @Published var providerState: ProviderState?

    /// Fee
    @Published var expressFeeRowViewModel: ExpressFeeRowData?

    // Main button
    @Published var mainButtonIsLoading: Bool = false
    @Published var mainButtonIsEnabled: Bool = false
    @Published var mainButtonState: MainButtonState = .swap
    @Published var alert: AlertBinder?

    let tangemIconProvider: TangemIconProvider

    @Published var legalText: AttributedString?

    // MARK: - Dependencies

    private let userWalletInfo: UserWalletInfo
    private let initialTokenItem: TokenItem
    private let feeFormatter: FeeFormatter
    private let balanceFormatter: BalanceFormatter
    private let expressProviderFormatter: ExpressProviderFormatter
    private let notificationManager: NotificationManager
    private let expressRepository: ExpressRepository
    private let interactor: ExpressInteractor
    private weak var coordinator: ExpressRoutable?

    // MARK: - Private

    private var sendingTransactionTask: Task<Void, Never>?
    private var refreshDataTimer: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        userWalletInfo: UserWalletInfo,
        initialTokenItem: TokenItem,
        feeFormatter: FeeFormatter,
        balanceFormatter: BalanceFormatter,
        expressProviderFormatter: ExpressProviderFormatter,
        notificationManager: NotificationManager,
        expressRepository: ExpressRepository,
        interactor: ExpressInteractor,
        coordinator: ExpressRoutable
    ) {
        self.userWalletInfo = userWalletInfo
        self.initialTokenItem = initialTokenItem
        self.feeFormatter = feeFormatter
        self.balanceFormatter = balanceFormatter
        self.expressProviderFormatter = expressProviderFormatter
        self.notificationManager = notificationManager
        self.expressRepository = expressRepository
        self.interactor = interactor
        self.coordinator = coordinator
        tangemIconProvider = CommonTangemIconProvider(config: userWalletInfo.config)

        Analytics.log(event: .swapScreenOpenedSwap, params: [.token: initialTokenItem.currencySymbol])
        setupView()
        bind()
    }

    func userDidTapMaxAmount() {
        guard let provider = interactor.getSource().value?.availableBalanceProvider,
              let sourceBalance = provider.balanceType.value else {
            return
        }

        updateSendDecimalValue(to: sourceBalance)
    }

    func userDidTapSwapSwappingItemsButton() {
        Analytics.log(.swapButtonSwipe)
        interactor.swapPair()
    }

    func userDidTapChangeSourceButton() {
        if FeatureProvider.isAvailable(.accounts) {
            coordinator?.presentSwapTokenSelector(swapDirection: .toDestination(initialTokenItem))
        } else {
            coordinator?.presentSwappingTokenList(swapDirection: .toDestination(initialTokenItem))
        }
    }

    func userDidTapChangeDestinationButton() {
        if FeatureProvider.isAvailable(.accounts) {
            coordinator?.presentSwapTokenSelector(swapDirection: .fromSource(initialTokenItem))
        } else {
            coordinator?.presentSwappingTokenList(swapDirection: .fromSource(initialTokenItem))
        }
    }

    func userDidTapPriceChangeInfoButton(message: String) {
        alert = .init(title: "", message: message)
    }

    func didTapMainButton() {
        if let disabledLocalizedReason = userWalletInfo.config.getDisabledLocalizedReason(for: .swapping) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        switch mainButtonState {
        case .permitAndSwap:
            Analytics.log(.swapButtonPermitAndSwap)
        // [REDACTED_TODO_COMMENT]
        case .swap:
            sendTransaction()
        case .insufficientFunds:
            assertionFailure("Button should be disabled")
        }
    }

    func didCloseApproveSheet() {
        restartTimer()
    }

    func didCloseFeeSelectorSheet() {
        restartTimer()
    }

    func didTapCloseButton() {
        coordinator?.closeSwappingView()
    }
}

// MARK: - Navigation

private extension ExpressViewModel {
    @MainActor
    func openSuccessView(sentTransactionData: SentExpressTransactionData) {
        coordinator?.presentSuccessView(data: sentTransactionData)
    }

    func openApproveView() {
        guard case .permissionRequired(let permissionRequired, _) = interactor.getState() else {
            return
        }

        Task {
            guard let source = interactor.getSource().value,
                  let selectedProvider = await interactor.getSelectedProvider()?.provider else {
                return
            }

            var params: [Analytics.ParameterKey: String] = [
                .sendToken: source.tokenItem.currencySymbol,
                .provider: selectedProvider.name,
            ]

            params[.receiveToken] = interactor.getDestination()?.tokenItem.currencySymbol
            Analytics.log(event: .swapButtonGivePermission, params: params)

            await MainActor.run {
                coordinator?.presentApproveView(
                    source: source,
                    provider: selectedProvider,
                    selectedPolicy: permissionRequired.policy
                )
            }
        }
    }

    func openFeeSelectorView() {
        // If we have fees for choosing
        guard !interactor.getState().fees.isEmpty else {
            return
        }

        coordinator?.presentFeeSelectorView()
    }

    func presentProviderSelectorView() {
        Analytics.log(.swapProviderClicked)
        coordinator?.presentProviderSelectorView()
    }
}

// MARK: - View updates

private extension ExpressViewModel {
    func setupView() {
        let sender = interactor.getSource().value
        sendCurrencyViewModel = SendCurrencyViewModel(
            expressCurrencyViewModel: .init(
                viewType: .send,
                headerType: .action(name: Localization.swappingFromTitle),
                canChangeCurrency: sender?.id != .init(tokenItem: initialTokenItem)
            ),
            decimalNumberTextFieldViewModel: .init(maximumFractionDigits: sender?.tokenItem.decimalCount ?? 0)
        )

        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            expressCurrencyViewModel: .init(
                viewType: .receive,
                headerType: .action(name: Localization.swappingToTitle),
                canChangeCurrency: interactor.getDestination()?.id != .init(tokenItem: initialTokenItem)
            )
        )

        // First update
        updateSendView(wallet: interactor.getSource())
        updateReceiveView(wallet: interactor.getDestinationValue())
    }

    func bind() {
        sendCurrencyViewModel?
            .decimalNumberTextFieldViewModel
            .valuePublisher
            .handleEvents(receiveOutput: { [weak self] amount in
                self?.interactor.cancelRefresh()
                self?.updateSendFiatValue(amount: amount)
                self?.stopTimer()
            })
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .sink { [weak self] amount in
                self?.interactor.update(amount: amount, by: .amountChange)

                if let amount, amount > 0 {
                    self?.startTimer()
                }
            }
            .store(in: &bag)

        // Creates a publisher that emits changes in the notification list
        // based on a provided filter that compares the previous and new values
        let makeNotificationPublisher = { [notificationManager] filter in
            notificationManager
                .notificationPublisher
                .removeDuplicates()
                .scan(([NotificationViewInput](), [NotificationViewInput]())) { prev, new in
                    (prev.1, new)
                }
                .filter(filter)
                .map(\.1)
        }

        // Publisher for showing new notifications with a delay to prevent unwanted animations
        makeNotificationPublisher { $1.count >= $0.count }
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        // Publisher for immediate updates when notifications are removed (e.g., from 2 to 0 or 1)
        // to fix 'jumping' animation bug
        makeNotificationPublisher { $1.count < $0.count }
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        interactor.state
            .withWeakCaptureOf(self)
            .sink { $0.expressInteractorStateDidUpdated(state: $1) }
            .store(in: &bag)

        interactor.swappingPair
            .receive(on: DispatchQueue.main)
            .pairwise()
            .sink { [weak self] prev, pair in
                if pair.sender.value?.id != prev.sender.value?.id {
                    self?.updateSendView(wallet: pair.sender)
                }

                if pair.destination?.value?.id != prev.destination?.value?.id {
                    self?.updateReceiveView(wallet: pair.destination)
                }

                self?.updateMaxButtonVisibility(pair: pair)
            }
            .store(in: &bag)

        interactor
            .swappingPair
            .withWeakCaptureOf(self)
            .asyncMap { viewModel, pair -> Bool in
                do {
                    if let sender = pair.sender.value,
                       let destination = pair.destination?.value as? ExpressSourceWallet {
                        let oppositePair = ExpressManagerSwappingPair(source: destination, destination: sender)
                        let oppositeProviders = try await viewModel.expressRepository.getAvailableProviders(for: oppositePair)
                        return oppositeProviders.isEmpty
                    }
                    return true
                } catch {
                    return true
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSwapButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func updateSendDecimalValue(to value: Decimal) {
        sendCurrencyViewModel?.decimalNumberTextFieldViewModel.update(value: value)
        updateSendFiatValue(amount: value)
        interactor.update(amount: value, by: .amountChange)
    }

    // MARK: - Send view bubble

    func updateSendView(wallet: ExpressInteractor.Source) {
        sendCurrencyViewModel?.update(wallet: wallet, initialWalletId: .init(tokenItem: initialTokenItem))

        guard let tokenItem = wallet.value?.tokenItem else {
            updateSendFiatValue(amount: nil)
            return
        }

        // If we have amount then we should round and update it with new decimalCount
        guard let amount = sendCurrencyViewModel?.decimalNumberTextFieldViewModel.value else {
            updateSendFiatValue(amount: nil)
            return
        }

        let roundedAmount = amount.rounded(scale: tokenItem.decimalCount, roundingMode: .down)

        // Exclude unnecessary update
        guard roundedAmount != amount else {
            // update only fiat in case of another walletModel selection with another quote
            updateSendFiatValue(amount: amount)
            return
        }

        updateSendDecimalValue(to: roundedAmount)
    }

    func updateSendFiatValue(amount: Decimal?) {
        sendCurrencyViewModel?.updateSendFiatValue(
            amount: amount,
            tokenItem: interactor.getSource().value?.tokenItem
        )
    }

    func updateSendCurrencyHeaderState(state: ExpressInteractor.State) {
        switch state {
        case .restriction(.notEnoughBalanceForSwapping, _):
            sendCurrencyViewModel?.expressCurrencyViewModel.update(errorState: .insufficientFunds)
        case .restriction(.notEnoughAmountForTxValue, _),
             .restriction(.notEnoughAmountForFee, _) where interactor.getSource().value?.isFeeCurrency == true:
            sendCurrencyViewModel?.expressCurrencyViewModel.update(errorState: .insufficientFunds)
        case .restriction(.validationError(.minimumRestrictAmount(let minimumAmount), _), _):
            let errorText = Localization.transferMinAmountError(minimumAmount.string())
            sendCurrencyViewModel?.expressCurrencyViewModel.update(errorState: .error(errorText))
        default:
            sendCurrencyViewModel?.expressCurrencyViewModel.update(errorState: .none)
        }
    }

    // MARK: - Receive view bubble

    func updateReceiveView(wallet: ExpressInteractor.Destination?) {
        receiveCurrencyViewModel?.update(wallet: wallet, initialWalletId: .init(tokenItem: initialTokenItem))
    }

    func updateFiatValue(expectAmount: Decimal?) {
        receiveCurrencyViewModel?.updateFiatValue(
            expectAmount: expectAmount,
            tokenItem: interactor.getDestination()?.tokenItem
        )
    }

    // MARK: - Toolbar

    func updateMaxButtonVisibility(pair: ExpressInteractor.SwappingPair) {
        let sendingMainToken = pair.sender.value?.isMainToken == true
        let isSameNetwork = pair.sender.value?.tokenItem.blockchainNetwork == pair.destination?.value?.tokenItem.blockchainNetwork

        isMaxAmountButtonHidden = sendingMainToken && isSameNetwork
    }

    // MARK: - Update for state

    func expressInteractorStateDidUpdated(state: ExpressInteractor.State) {
        Task { @MainActor in
            await updateState(state: state)
        }
    }

    @MainActor
    func updateState(state: ExpressInteractor.State) async {
        updateFeeValue(state: state)
        await updateProviderView(state: state)
        updateMainButton(state: state)
        await updateLegalText(state: state)
        updateSendCurrencyHeaderState(state: state)

        switch state {
        case .idle:
            isSwapButtonLoading = false
            stopTimer()

            updateFiatValue(expectAmount: 0)
            receiveCurrencyViewModel?.expressCurrencyViewModel.updateHighPricePercentLabel(quote: .none)

        case .loading(let type):
            isSwapButtonLoading = true

            // Turn on skeletons only for full update
            guard type == .full else { return }

            receiveCurrencyViewModel?.update(cryptoAmountState: .loading)
            receiveCurrencyViewModel?.expressCurrencyViewModel.update(fiatAmountState: .loading)
            receiveCurrencyViewModel?.expressCurrencyViewModel.updateHighPricePercentLabel(quote: .none)

        case .restriction(let restriction, let quote):
            isSwapButtonLoading = false
            updateFiatValue(expectAmount: quote?.expectAmount)
            receiveCurrencyViewModel?.expressCurrencyViewModel.updateHighPricePercentLabel(quote: quote)

            // restart timer for pending approve transaction
            switch restriction {
            case .hasPendingApproveTransaction:
                restartTimer()
            default:
                stopTimer()
            }

        case .permissionRequired(_, let quote), .previewCEX(_, let quote), .readyToSwap(_, let quote):
            isSwapButtonLoading = false
            restartTimer()

            updateFiatValue(expectAmount: quote.expectAmount)
            receiveCurrencyViewModel?.expressCurrencyViewModel.updateHighPricePercentLabel(quote: quote)
        }
    }

    @MainActor
    func updateProviderView(state: ExpressInteractor.State) async {
        switch state {
        case .idle:
            providerState = .none
        case .loading(let type):
            if type == .full {
                providerState = .loading
            }
        default:
            if let providerRowViewModel = await mapToProviderRowViewModel() {
                providerState = .loaded(data: providerRowViewModel)
            } else {
                providerState = .none
            }
        }
    }

    func updateFeeValue(state: ExpressInteractor.State) {
        switch state {
        case .restriction(.notEnoughAmountForTxValue, _):
            // Single estimated fee just for UI
            updateExpressFeeRowViewModel(fees: .loading)
        case .restriction(.notEnoughAmountForFee, _):
            updateExpressFeeRowViewModel(fees: .success(state.fees))
        case .previewCEX(let state, _) where state.isExemptFee:
            // Don't show fee row if transaction has fee exemption
            expressFeeRowViewModel = nil
        case .previewCEX(let state, _):
            updateExpressFeeRowViewModel(fees: .success(state.fees))
        case .readyToSwap(let state, _):
            updateExpressFeeRowViewModel(fees: .success(state.fees))
        case .loading(.fee):
            updateExpressFeeRowViewModel(fee: .loading, action: nil)
        case .idle, .restriction, .loading(.full), .permissionRequired:
            // We have decided that will not give a choose for .permissionRequired state also
            expressFeeRowViewModel = nil
        case .loading(.refreshRates):
            break
        }
    }

    func updateExpressFeeRowViewModel(fees: LoadingResult<ExpressInteractor.Fees, Never>) {
        switch fees {
        case .loading:
            updateExpressFeeRowViewModel(fee: .loading, action: nil)
        case .success(let fees):
            guard let fee = try? fees.selectedFee().amount.value else {
                expressFeeRowViewModel = nil
                return
            }

            var action: (() -> Void)?
            // If fee is one option then don't open selector
            if !fees.isFixed {
                action = weakify(self, forFunction: ExpressViewModel.openFeeSelectorView)
            }

            do {
                let sender = try interactor.getSourceWallet()
                let formattedFee = feeFormatter.format(fee: fee, tokenItem: sender.feeTokenItem)
                updateExpressFeeRowViewModel(fee: .loaded(text: formattedFee), action: action)
            } catch {
                updateExpressFeeRowViewModel(fee: .noData, action: action)
            }
        }
    }

    func updateExpressFeeRowViewModel(fee: LoadableTextView.State, action: (() -> Void)?) {
        expressFeeRowViewModel = ExpressFeeRowData(
            title: Localization.commonNetworkFeeTitle,
            subtitle: fee,
            action: action
        )
    }

    func updateMainButton(state: ExpressInteractor.State) {
        switch state {
        case .idle, .loading(type: .full):
            mainButtonState = .swap
            mainButtonIsEnabled = false
        case .loading(type: .fee):
            mainButtonIsEnabled = false
        case .loading(type: .refreshRates):
            // Do nothing
            break
        case .restriction(let type, _):
            switch type {
            case .hasPendingTransaction,
                 .hasPendingApproveTransaction,
                 .requiredRefresh,
                 .tooSmallAmountForSwapping,
                 .tooBigAmountForSwapping,
                 .noSourceTokens,
                 .noDestinationTokens,
                 .validationError,
                 .notEnoughReceivedAmount:
                mainButtonState = .swap
            case .notEnoughBalanceForSwapping,
                 .notEnoughAmountForFee,
                 .notEnoughAmountForTxValue:
                mainButtonState = .insufficientFunds
            }

            mainButtonIsEnabled = false
        case .permissionRequired:
            mainButtonState = .swap
            mainButtonIsEnabled = false
        case .readyToSwap, .previewCEX:
            mainButtonState = .swap
            mainButtonIsEnabled = true
        }
    }

    @MainActor
    func updateLegalText(state: ExpressInteractor.State) async {
        switch state {
        case .loading(.refreshRates), .loading(.fee):
            break
        case .idle, .loading(.full):
            legalText = nil
        case .restriction, .permissionRequired, .previewCEX, .readyToSwap:
            legalText = await interactor.getSelectedProvider()?.provider.legalText(branch: .swap)
        }
    }
}

// MARK: - Mapping

private extension ExpressViewModel {
    func mapToProviderRowViewModel() async -> ProviderRowViewModel? {
        guard let selectedProvider = await interactor.getSelectedProvider() else {
            return nil
        }

        let state = await selectedProvider.getState()
        if state.isError {
            // Don't show a error provider
            return nil
        }

        let subtitle = expressProviderFormatter.mapToRateSubtitle(
            state: state,
            senderCurrencyCode: interactor.getSource().value?.tokenItem.currencySymbol,
            destinationCurrencyCode: interactor.getDestination()?.tokenItem.currencySymbol,
            option: .exchangeRate
        )

        let providerBadge = await expressProviderFormatter.mapToBadge(availableProvider: selectedProvider)
        let badge: ProviderRowViewModel.Badge? = switch providerBadge {
        case .none: .none
        case .bestRate: .bestRate
        case .fcaWarning: .fcaWarning
        case .permissionNeeded: .permissionNeeded
        }

        return ProviderRowViewModel(
            provider: expressProviderFormatter.mapToProvider(provider: selectedProvider.provider),
            titleFormat: .name,
            isDisabled: false,
            badge: badge,
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
        guard interactor.getState().isAvailableToSendTransaction else {
            return
        }

        stopTimer()
        mainButtonIsLoading = true
        sendingTransactionTask?.cancel()
        sendingTransactionTask = runTask(in: self) { root in
            do {
                let sentTransactionData = try await root.interactor.send()
                try Task.checkCancellation()

                await root.openSuccessView(sentTransactionData: sentTransactionData)
            } catch {
                await root.proceed(error: error)
            }

            await MainActor.run {
                root.mainButtonIsLoading = false
            }
        }
    }

    @MainActor
    func proceed(error: Error) {
        switch error {
        case let error where error.isCancellationError:
            restartTimer()

        case TransactionDispatcherResult.Error.demoAlert:
            alert = AlertBuilder.makeDemoAlert()

        case let error as ExpressAPIError:
            let message = error.localizedMessage
            alert = AlertBinder(title: Localization.commonError, message: message)

        case let error as ValidationError:
            guard let sender = interactor.getSource().value else {
                fallthrough
            }

            let factory = BlockchainSDKNotificationMapper(
                tokenItem: sender.tokenItem,
                feeTokenItem: sender.feeTokenItem
            )

            let validationErrorEvent = factory.mapToValidationErrorEvent(error)
            let message = validationErrorEvent.description ?? error.localizedDescription
            alert = AlertBinder(title: Localization.commonError, message: message)

        default:
            alert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
        }
    }
}

// MARK: - NotificationTapDelegate

extension ExpressViewModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        guard
            let notification = notificationInputs.first(where: { $0.id == id }),
            let event = notification.settings.event as? ExpressNotificationEvent
        else {
            return
        }

        switch action {
        case .empty:
            break
        case .refresh:
            interactor.refresh(type: .full)
        case .openFeeCurrency:
            openFeeCurrency()
        case .reduceAmountBy(let amount, _, _):
            guard let value = sendCurrencyViewModel?.decimalNumberTextFieldViewModel.value else {
                ExpressLogger.info("Couldn't find sendDecimalValue")
                return
            }

            updateSendDecimalValue(to: value - amount)
        case .reduceAmountTo(let amount, _):
            updateSendDecimalValue(to: amount)
        case .leaveAmount(let amount, _):
            guard let balance = interactor.getSource().value?.availableBalanceProvider.balanceType.value else {
                ExpressLogger.info("Couldn't find sender balance")
                return
            }

            var targetValue = balance - amount
            if let feeValue = feeValue(from: event) {
                targetValue -= feeValue
            }

            updateSendDecimalValue(to: targetValue)
        case .givePermission:
            openApproveView()
        case .generateAddresses,
             .backupCard,
             .refreshFee,
             .goToProvider,
             .addHederaTokenAssociation,
             .retryKaspaTokenTransaction,
             .openLink,
             .stake,
             .openFeedbackMail,
             .openAppStoreReview,
             .swap,
             .support,
             .openCurrency,
             .seedSupportNo,
             .seedSupportYes,
             .seedSupport2No,
             .seedSupport2Yes,
             .unlock,
             .addTokenTrustline,
             .openMobileFinishActivation,
             .openMobileUpgrade,
             .tangemPaySync,
             .activate,
             .allowPushPermissionRequest,
             .postponePushPermissionRequest:
            return
        }
    }
}

// MARK: - NotificationTapDelegate helpers

private extension ExpressViewModel {
    func openFeeCurrency() {
        guard let sender = interactor.getSource().value else {
            return
        }

        coordinator?.presentFeeCurrency(feeCurrency: .init(
            userWalletId: userWalletInfo.id,
            tokenItem: sender.feeTokenItem
        ))
    }

    func feeValue(from event: ExpressNotificationEvent) -> Decimal? {
        switch event {
        case .validationErrorEvent(_, let context) where context.isFeeCurrency:
            return context.feeValue
        case .permissionNeeded,
             .refreshRequired,
             .hasPendingTransaction,
             .hasPendingApproveTransaction,
             .notEnoughFeeForTokenTx,
             .tooSmallAmountToSwap,
             .tooBigAmountToSwap,
             .noDestinationTokens,
             .feeWillBeSubtractFromSendingAmount,
             .notEnoughReceivedAmountForReserve,
             .withdrawalNotificationEvent,
             .validationErrorEvent,
             .verificationRequired,
             .cexOperationFailed,
             .refunded,
             .longTimeAverageDuration:
            return nil
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
        ExpressLogger.info("Stop timer")
        refreshDataTimer?.cancel()
    }

    func startTimer() {
        ExpressLogger.info("Start timer")
        refreshDataTimer = Just(())
            .delay(for: 10, scheduler: DispatchQueue.main)
            .sink { [weak self] in
                ExpressLogger.info("Timer call autoupdate")
                self?.interactor.refresh(type: .refreshRates)
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
        case permitAndSwap

        var title: String {
            switch self {
            case .swap:
                return Localization.swappingSwapAction
            case .insufficientFunds:
                return Localization.swappingInsufficientFunds
            case .permitAndSwap:
                return Localization.swappingPermitAndSwap
            }
        }

        func getIcon(tangemIconProvider: TangemIconProvider) -> MainButton.Icon? {
            switch self {
            case .swap, .permitAndSwap:
                return tangemIconProvider.getMainButtonIcon()
            case .insufficientFunds:
                return .none
            }
        }
    }
}

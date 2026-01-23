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
import TangemMacro
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
    @Published var expressFeeRowViewModel: FeeCompactViewModel?

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
    private var refreshDataTask: Task<Void, Error>?
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

        Analytics.log(
            event: .swapScreenOpenedSwap,
            params: [.token: initialTokenItem.currencySymbol],
            analyticsSystems: .all
        )
        setupView()
        bind()
    }

    deinit {
        ExpressLogger.debug("deinit")
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

    func userDidTapFeeRow() {
        openFeeSelectorView()
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
        guard case .permissionRequired(let permissionRequired, let provider, _) = interactor.getState() else {
            return
        }

        guard let source = interactor.getSource().value else {
            return
        }

        let selectedProvider = provider.provider
        var params: [Analytics.ParameterKey: String] = [
            .sendToken: source.tokenItem.currencySymbol,
            .provider: selectedProvider.name,
        ]

        params[.receiveToken] = interactor.getDestination()?.tokenItem.currencySymbol
        Analytics.log(event: .swapButtonGivePermission, params: params)

        coordinator?.presentApproveView(
            source: source,
            provider: selectedProvider,
            selectedPolicy: permissionRequired.policy
        )
    }

    func openFeeSelectorView() {
        guard let tokenFeeProvidersManager = interactor.tokenFeeProvidersManager else {
            ExpressLogger.debug("`openFeeSelectorView()` called while loading state")
            return
        }

        guard tokenFeeProvidersManager.supportFeeSelection else {
            ExpressLogger.debug("`openFeeSelectorView()` called while not `supportFeeSelection`")
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
            .debounce(for: .seconds(1), scheduler: .main, if: { $0 != nil })
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
            .receiveOnMain()
            .assign(to: &$isSwapButtonDisabled)
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
        case .restriction(.notEnoughBalanceForSwapping, _, _):
            sendCurrencyViewModel?.expressCurrencyViewModel.update(errorState: .insufficientFunds)
        case .restriction(.notEnoughAmountForTxValue(_, let isFeeCurrency), _, _) where isFeeCurrency,
             .restriction(.notEnoughAmountForFee(let isFeeCurrency), _, _) where isFeeCurrency:
            sendCurrencyViewModel?.expressCurrencyViewModel.update(errorState: .insufficientFunds)
        case .restriction(.validationError(.minimumRestrictAmount(let minimumAmount), _), _, _):
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
        updateLegalText(state: state)
        updateSendCurrencyHeaderState(state: state)

        switch state {
        case .idle, .preloadRestriction:
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

        case .restriction(.hasPendingApproveTransaction, _, let quote):
            isSwapButtonLoading = false
            updateFiatValue(expectAmount: quote?.expectAmount)
            receiveCurrencyViewModel?.expressCurrencyViewModel.updateHighPricePercentLabel(quote: quote)

        case .requiredRefresh(_, let quote), .restriction(_, _, let quote):
            isSwapButtonLoading = false
            updateFiatValue(expectAmount: quote?.expectAmount)
            receiveCurrencyViewModel?.expressCurrencyViewModel.updateHighPricePercentLabel(quote: quote)
            stopTimer()

        case .permissionRequired(_, _, let quote), .previewCEX(_, _, let quote), .readyToSwap(_, _, let quote):
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
        case .loading(.full):
            providerState = .loading
        case .loading:
            // Do noting for other cases
            break
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
        case .loading(.refreshRates):
            break

        case .previewCEX(let state, _, _) where state.isExemptFee:
            // Don't show fee row if transaction has fee exemption
            expressFeeRowViewModel = nil

        case .loading(.fee):
            expressFeeRowViewModel?.selectedFeeComponents = .loading

        case .restriction(.notEnoughAmountForFee, let context, _):
            updateExpressFeeRowViewModel(tokenFeeProvidersManager: context.tokenFeeProvidersManager)

        case .previewCEX(_, let context, _):
            updateExpressFeeRowViewModel(tokenFeeProvidersManager: context.tokenFeeProvidersManager)

        case .readyToSwap(_, let context, _):
            updateExpressFeeRowViewModel(tokenFeeProvidersManager: context.tokenFeeProvidersManager)

        case .idle, .loading, .preloadRestriction, .restriction, .requiredRefresh, .permissionRequired:
            // We have decided that will not give a choose for .permissionRequired state also
            expressFeeRowViewModel = nil
        }
    }

    func updateExpressFeeRowViewModel(tokenFeeProvidersManager: TokenFeeProvidersManager) {
        let viewModel = FeeCompactViewModel()
        viewModel.bind(
            selectedFeePublisher: tokenFeeProvidersManager.selectedFeeProvider.selectedTokenFeePublisher,
            supportFeeSelectionPublisher: tokenFeeProvidersManager.supportFeeSelectionPublisher
        )

        expressFeeRowViewModel = viewModel
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

        case .restriction(.notEnoughBalanceForSwapping, _, _),
             .restriction(.notEnoughAmountForFee, _, _),
             .restriction(.notEnoughAmountForTxValue, _, _):
            mainButtonState = .insufficientFunds

        case .requiredRefresh,
             .preloadRestriction,
             .restriction(.hasPendingTransaction, _, _),
             .restriction(.hasPendingApproveTransaction, _, _),
             .restriction(.tooSmallAmountForSwapping, _, _),
             .restriction(.tooBigAmountForSwapping, _, _),
             .restriction(.validationError, _, _),
             .restriction(.notEnoughReceivedAmount, _, _):
            mainButtonState = .swap
            mainButtonIsEnabled = false

        case .permissionRequired:
            mainButtonState = .swap
            mainButtonIsEnabled = false

        case .readyToSwap, .previewCEX:
            mainButtonState = .swap
            mainButtonIsEnabled = true
        }
    }

    func updateLegalText(state: ExpressInteractor.State) {
        switch state {
        case .loading(.refreshRates), .loading(.fee):
            break
        case .idle, .loading(.full), .preloadRestriction, .requiredRefresh:
            legalText = nil
        case .restriction(_, let provider, _),
             .permissionRequired(_, let provider, _),
             .previewCEX(_, let provider, _),
             .readyToSwap(_, let provider, _):
            legalText = provider.provider.legalText(branch: .swap)
        }
    }
}

// MARK: - Mapping

private extension ExpressViewModel {
    func mapToProviderRowViewModel() async -> ProviderRowViewModel? {
        guard let selectedProvider = interactor.getState().context?.availableProvider else {
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

            let factory = BlockchainSDKNotificationMapper(tokenItem: sender.tokenItem)
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
        refreshDataTask?.cancel()
    }

    func startTimer() {
        ExpressLogger.info("Start timer")
        refreshDataTask = Task { @MainActor [weak self] in
            try await Task.sleep(for: .seconds(10))
            try Task.checkCancellation()
            ExpressLogger.info("Timer call autoupdate")
            self?.interactor.refresh(type: .refreshRates)
        }
    }
}

extension ExpressViewModel {
    @RawCaseName
    enum ProviderState: Identifiable {
        case loading
        case loaded(data: ProviderRowViewModel)
    }

    @RawCaseName
    enum MainButtonState: Identifiable {
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

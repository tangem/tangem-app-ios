//
//  SwapNotificationManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk
import TangemAssets
import TangemExpress
import TangemFoundation
import TangemLocalization

protocol SwapNotificationManager: NotificationManager {
    func setup(
        sourceTokenInput: SendSourceTokenInput,
        receiveTokenInput: SendReceiveTokenInput,
        swapModelStateProvider: SwapModelStateProvider,
    )
}

final class CommonSwapNotificationManager {
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])

    private let balanceFormatter = BalanceFormatter()

    private weak var delegate: NotificationTapDelegate?
    private let analyticsServices: ThreadSafeContainer<[UserWalletId: NotificationsAnalyticsService]> = [:]

    private var setupCancellable: AnyCancellable?
    private var analyticsServiceCancellable: AnyCancellable?

    private func analyticsService(for userWalletId: UserWalletId) -> NotificationsAnalyticsService {
        if let analyticsService = analyticsServices.read()[userWalletId] {
            return analyticsService
        }

        let analyticsService = NotificationsAnalyticsService(userWalletId: userWalletId)
        analyticsServices.mutate { $0[userWalletId] = analyticsService }
        return analyticsService
    }
}

// MARK: - Private

private extension CommonSwapNotificationManager {
    func bind(
        sourceTokenInput: SendSourceTokenInput,
        receiveTokenInput: SendReceiveTokenInput,
        swapModelStateProvider: SwapModelStateProvider,
    ) {
        setupCancellable = Publishers.CombineLatest3(
            sourceTokenInput.sourceTokenPublisher,
            receiveTokenInput.receiveTokenPublisher,
            swapModelStateProvider.statePublisher
                .filter { $0.filter(loading: [.providers, .rates]) }
        )
        .withWeakCaptureOf(self)
        .map { $0.mapToNotificationInputs(source: $1.0, receive: $1.1, state: $1.2) }
        .assign(to: \.notificationInputsSubject.value, on: self, ownership: .weak)

        analyticsServiceCancellable = Publishers.CombineLatest(
            sourceTokenInput.sourceTokenPublisher.compactMap { $0.value },
            notificationPublisher.debounce(for: 0.1, scheduler: DispatchQueue.main)
        )
        .withWeakCaptureOf(self)
        .sink(receiveValue: { manager, args in
            let (source, notifications) = args
            let analyticsService = manager.analyticsService(for: source.userWalletInfo.id)
            analyticsService.sendEventsIfNeeded(for: notifications)
        })
    }

    func mapToNotificationInputs(
        source: LoadingResult<SendSourceToken, any Error>,
        receive: LoadingResult<SendReceiveToken, any Error>,
        state: SwapModel.ProvidersState
    ) -> [NotificationViewInput] {
        let factory = NotificationsFactory()
        let events = mapToEvents(source: source, receive: receive, state: state)
        let inputs = events.map { event in
            let input = factory.buildNotificationInput(for: event) { [weak self] id, actionType in
                self?.delegate?.didTapNotification(with: id, action: actionType)
            }

            return input
        }

        return inputs
    }

    func mapToEvents(
        source: LoadingResult<SendSourceToken, any Error>,
        receive: LoadingResult<SendReceiveToken, any Error>,
        state: SwapModel.ProvidersState
    ) -> [SwapNotificationEvent] {
        switch (source, receive, state) {
        // Expected when couldn't load the providers list
        case (_, _, .failure):
            return [.refreshRequired(title: Localization.commonError, message: Localization.commonUnknownError)]

        case (.success(let source), .success(let receive), .loaded(.swap(_, let providers), .idle)) where providers.isEmpty:
            let analyticsParams: [Analytics.ParameterKey: String] = [
                .sendToken: source.tokenItem.currencySymbol,
                .sendBlockchain: source.tokenItem.blockchain.displayName,
                .receiveToken: receive.tokenItem.currencySymbol,
                .receiveBlockchain: receive.tokenItem.blockchain.displayName,
            ]
            return [.unsupportedPair(analyticsParams: analyticsParams)]

        case (.success(let source), .success(let receive), .loaded(.transfer, let state)):
            var events = mapLoadedStateEvents(source: source, receive: receive, provider: nil, state: state)
            if let warning = mapToCustomFeeWarningEvent(sourceToken: source) {
                events.append(warning)
            }

            return events

        case (.success(let source), .success(let receive), .loaded(.swap(let selected, _), let state)):
            let events = mapLoadedStateEvents(source: source, receive: receive, provider: selected, state: state)
            return events

        default:
            return []
        }
    }

    func mapLoadedStateEvents(
        source: SendSourceToken,
        receive: SendReceiveToken,
        provider: ExpressAvailableProvider?,
        state: SwapModel.LoadedState
    ) -> [SwapNotificationEvent] {
        let sourceTokenItemSymbol = source.tokenItem.currencySymbol

        var analyticsParams: [Analytics.ParameterKey: String] = [:]
        analyticsParams[.sendToken] = source.tokenItem.currencySymbol
        analyticsParams[.receiveToken] = receive.tokenItem.currencySymbol
        analyticsParams[.provider] = provider?.provider.name

        switch state {
        case .idle:
            return []

        case .requiredRefresh(occurredError: let occurredError as ExpressAPIError, _):
            // For only a express error we use "Service temporary unavailable"
            // or "Selected pair temporarily unavailable" depending on the error code.
            analyticsParams[.errorCode] = "\(occurredError.errorCode.rawValue)"
            analyticsParams[.sendBlockchain] = source.tokenItem.blockchain.displayName
            analyticsParams[.receiveBlockchain] = receive.tokenItem.blockchain.displayName

            return [
                .refreshRequired(
                    title: occurredError.localizedTitle,
                    message: occurredError.localizedMessage,
                    expressErrorCode: occurredError.errorCode,
                    analyticsParams: analyticsParams
                ),
            ]

        case .requiredRefresh:
            return [.refreshRequired(title: Localization.commonError, message: Localization.commonUnknownError)]

        case .restriction(.tooSmallAmountForSwapping(let minAmount, let currencySymbol), _):
            let formatted = balanceFormatter.formatCryptoBalance(minAmount, currencyCode: currencySymbol)
            return [.tooSmallAmountToSwap(minimumAmountText: formatted)]

        case .restriction(.tooBigAmountForSwapping(let maxAmount, let currencySymbol), _):
            let formatted = balanceFormatter.formatCryptoBalance(maxAmount, currencyCode: currencySymbol)
            return [.tooBigAmountToSwap(maximumAmountText: formatted)]

        case .restriction(.hasPendingTransaction, _):
            return [.hasPendingTransaction(symbol: sourceTokenItemSymbol)]

        case .restriction(.hasPendingApproveTransaction, _):
            return [.hasPendingApproveTransaction]

        case .restriction(.notEnoughBalanceForSwapping, _):
            let noticeAnalyticsParams: [Analytics.ParameterKey: String] = [
                .token: source.tokenItem.currencySymbol,
                .blockchain: source.tokenItem.blockchain.displayName,
            ]
            return [.notEnoughBalanceForSwapping(analyticsParams: noticeAnalyticsParams)]

        case .restriction(.validationError(let validationError), _):
            if let event = mapValidationError(source: source, validationError: validationError) {
                return [event]
            }

            return []

        case .restriction(.notEnoughAmountForFee(let isFeeCurrency), _) where isFeeCurrency,
             .restriction(.notEnoughAmountForTxValue(_, let isFeeCurrency), _) where isFeeCurrency:
            return []

        case .restriction(.notEnoughAmountForFee, _), .restriction(.notEnoughAmountForTxValue, _):
            let feeBlockchain = source.tokenItem.blockchain

            let noticeAnalyticsParams: [Analytics.ParameterKey: String] = [
                .token: source.tokenItem.currencySymbol,
                .blockchain: source.tokenItem.blockchain.displayName,
            ]

            return [
                .notEnoughFeeForTokenTx(
                    mainTokenName: feeBlockchain.displayName,
                    mainTokenSymbol: feeBlockchain.currencySymbol,
                    blockchainIconAsset: NetworkImageProvider().provide(by: feeBlockchain, filled: true),
                    analyticsParams: noticeAnalyticsParams
                ),
            ]

        case .restriction(.notEnoughReceivedAmount(let minAmount, let tokenSymbol), _):
            return [.notEnoughReceivedAmountForReserve(amountFormatted: "\(minAmount.formatted()) \(tokenSymbol)")]

        case .restriction(.incompleteBackup, _):
            return [.incompleteBackup]

        case .permissionRequired:
            return [
                .permissionNeeded(
                    providerName: provider?.provider.name ?? "",
                    currencyCode: sourceTokenItemSymbol,
                    analyticsParams: analyticsParams
                ),
            ]

        case .previewCEX(let previewCEX):
            var events: [SwapNotificationEvent] = []

            if let hpi = previewCEX.quote.highPriceImpact, !hpi.level.isNegligible {
                events.append(
                    .highPriceImpactWarning(
                        level: hpi.level,
                        analyticsParams: hpiAnalyticsParams(base: analyticsParams, source: source, receive: receive)
                    )
                )
            }

            if previewCEX.subtractFee.subtractFee > 0 {
                let feeTokenItem = previewCEX.subtractFee.feeTokenItem
                let feeFiatValue = BalanceConverter().convertToFiat(previewCEX.subtractFee.subtractFee, currencyId: feeTokenItem.currencyId ?? "")

                let cryptoAmountFormatted = balanceFormatter.formatCryptoBalance(previewCEX.subtractFee.subtractFee, currencyCode: feeTokenItem.currencySymbol)
                let fiatAmountFormatted = balanceFormatter.formatFiatBalance(feeFiatValue)

                let event = SwapNotificationEvent.feeWillBeSubtractFromSendingAmount(
                    cryptoAmountFormatted: cryptoAmountFormatted,
                    fiatAmountFormatted: fiatAmountFormatted
                )

                events.append(event)
            }

            if let notification = previewCEX.notification {
                let factory = BlockchainSDKNotificationMapper(tokenItem: source.tokenItem)
                let withdrawalNotification = factory.mapToWithdrawalNotificationEvent(notification)
                let event = SwapNotificationEvent.withdrawalNotificationEvent(withdrawalNotification)
                events.append(event)
            }

            return events

        case .readyToSwap(let readyState):
            var events: [SwapNotificationEvent] = []

            if let hpi = readyState.quote.highPriceImpact, !hpi.level.isNegligible {
                events.append(
                    .highPriceImpactWarning(
                        level: hpi.level,
                        analyticsParams: hpiAnalyticsParams(base: analyticsParams, source: source, receive: receive)
                    )
                )
            }

            return events

        case .readyToApproveAndSwap(let readyState):
            var events: [SwapNotificationEvent] = []

            if let hpi = readyState.quote.highPriceImpact, !hpi.level.isNegligible {
                events.append(
                    .highPriceImpactWarning(
                        level: hpi.level,
                        analyticsParams: hpiAnalyticsParams(base: analyticsParams, source: source, receive: receive)
                    )
                )
            }

            return events

        case .readyToTransfer(let transferState):
            var events: [SwapNotificationEvent] = []

            if transferState.subtractFee.subtractFee > 0 {
                let feeTokenItem = transferState.subtractFee.feeTokenItem
                let feeFiatValue = BalanceConverter().convertToFiat(transferState.subtractFee.subtractFee, currencyId: feeTokenItem.currencyId ?? "")

                let cryptoAmountFormatted = balanceFormatter.formatCryptoBalance(transferState.subtractFee.subtractFee, currencyCode: feeTokenItem.currencySymbol)
                let fiatAmountFormatted = balanceFormatter.formatFiatBalance(feeFiatValue)

                let event = SwapNotificationEvent.feeWillBeSubtractFromSendingAmount(
                    cryptoAmountFormatted: cryptoAmountFormatted,
                    fiatAmountFormatted: fiatAmountFormatted
                )

                events.append(event)
            }

            if let notification = transferState.notification {
                let factory = BlockchainSDKNotificationMapper(tokenItem: source.tokenItem)
                let withdrawalNotification = factory.mapToWithdrawalNotificationEvent(notification)
                events.append(.withdrawalNotificationEvent(withdrawalNotification))
            }

            return events
        }
    }

    func mapToCustomFeeWarningEvent(sourceToken: SendSourceToken) -> SwapNotificationEvent? {
        let transferableToken = sourceToken as? SendTransferableToken
        guard let tokenFeeProvidersManager = transferableToken?.tokenFeeProvidersManager else {
            return nil
        }

        let customFeeWarning = CustomFeeThresholdEvaluator.evaluate(
            selectedFee: tokenFeeProvidersManager.selectedFeeProvider.selectedTokenFee,
            feeValues: tokenFeeProvidersManager.selectedFeeProvider.fees
        )

        return customFeeWarning.map { .customFeeWarning($0) }
    }

    private func hpiAnalyticsParams(
        base analyticsParams: [Analytics.ParameterKey: String],
        source: any SendSourceToken,
        receive: any SendReceiveToken
    ) -> [Analytics.ParameterKey: String] {
        var params = analyticsParams
        params[.sendBlockchain] = source.tokenItem.blockchain.displayName
        params[.receiveBlockchain] = receive.tokenItem.blockchain.displayName
        return params
    }

    func mapValidationError(source: any SendSourceToken, validationError: ValidationError) -> SwapNotificationEvent? {
        let factory = BlockchainSDKNotificationMapper(tokenItem: source.tokenItem)
        let validationErrorEvent = factory.mapToValidationErrorEvent(validationError)

        switch validationErrorEvent {
        case .invalidNumber:
            return .refreshRequired(title: Localization.commonError, message: validationError.localizedDescription)

        case .insufficientBalance:
            assertionFailure("It has to be mapped to a restriction type for insufficient balance")
            return nil

        case .insufficientBalanceForFee:
            assertionFailure("It has to be mapped to a restriction type for insufficient fee")
            notificationInputsSubject.value = []
            return nil

        case .minimumRestrictAmount:
            // The error will be displayed above the amount input field
            return nil

        case .dustRestriction,
             .existentialDeposit,
             .amountExceedMaximumUTXO,
             .insufficientAmountToReserveAtDestination,
             .cardanoCannotBeSentBecauseHasTokens,
             .cardanoInsufficientBalanceToSendToken,
             .notEnoughMana,
             .manaLimit,
             .remainingAmountIsLessThanRentExemption,
             .sendingAmountIsLessThanRentExemption,
             .koinosInsufficientBalanceToSendKoin,
             .destinationMemoRequired,
             .noTrustlineAtDestination:
            return .validationErrorEvent(event: validationErrorEvent)
        }
    }
}

// MARK: - NotificationManager

extension CommonSwapNotificationManager: SwapNotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate
    }

    func setup(
        sourceTokenInput: any SendSourceTokenInput,
        receiveTokenInput: any SendReceiveTokenInput,
        swapModelStateProvider: any SwapModelStateProvider
    ) {
        bind(
            sourceTokenInput: sourceTokenInput,
            receiveTokenInput: receiveTokenInput,
            swapModelStateProvider: swapModelStateProvider
        )
    }

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}

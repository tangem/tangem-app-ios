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

    private weak var delegate: NotificationTapDelegate?
    private var analyticsService: NotificationsAnalyticsService

    private var setupCancellable: AnyCancellable?
    private var analyticsServiceCancellable: AnyCancellable?

    init(userWalletId: UserWalletId) {
        analyticsService = NotificationsAnalyticsService(userWalletId: userWalletId)
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
        )
        .withWeakCaptureOf(self)
        .map { $0.mapToNotificationInputs(source: $1.0, receive: $1.1, state: $1.2) }
        .assign(to: \.notificationInputsSubject.value, on: self, ownership: .weak)

        analyticsServiceCancellable = notificationPublisher
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { manager, notifications in
                manager.analyticsService.sendEventsIfNeeded(for: notifications)
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
    ) -> [ExpressNotificationEvent] {
        switch (source, receive, state) {
        case (.success, .failure(ExpressDestinationServiceError.destinationNotFound(let source)), _):
            return [.noDestinationTokens(tokenName: source.name)]

        case (.failure(ExpressDestinationServiceError.sourceNotFound(let destination)), .success, _):
            return [.noDestinationTokens(tokenName: destination.name)]

        // Expected when couldn't load the providers list
        case (_, _, .failure):
            return [.refreshRequired(title: Localization.commonError, message: Localization.commonUnknownError)]

        case (.success, .success(let receive), .loaded(let providers, _)) where providers.providers.isEmpty:
            return [.tokenNotSupportedForSwap(tokenName: receive.tokenItem.name)]

        case (.success(let source), .success(let receive), .loaded(let providers, let state)):
            let events = mapLoadedStateEvents(source: source, receive: receive, provider: providers.selected, state: state)
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
    ) -> [ExpressNotificationEvent] {
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

            return [
                .refreshRequired(
                    title: occurredError.localizedTitle,
                    message: occurredError.localizedMessage,
                    expressErrorCode: occurredError.errorCode,
                    analyticsParams: analyticsParams
                ),
            ]

        case .requiredRefresh(occurredError: let occurredError, _):
            return [.refreshRequired(title: Localization.commonError, message: Localization.commonUnknownError)]

        case .restriction(.tooSmallAmountForSwapping(let minAmount), _):
            let sourceTokenItemSymbol = source.tokenItem.currencySymbol
            return [.tooSmallAmountToSwap(minimumAmountText: "\(minAmount) \(sourceTokenItemSymbol)")]

        case .restriction(.tooBigAmountForSwapping(let maxAmount), _):
            return [.tooBigAmountToSwap(maximumAmountText: "\(maxAmount) \(sourceTokenItemSymbol)")]

        case .restriction(.hasPendingTransaction, _):
            return [.hasPendingTransaction(symbol: sourceTokenItemSymbol)]

        case .restriction(.hasPendingApproveTransaction, _):
            return [.hasPendingApproveTransaction]

        case .restriction(.notEnoughBalanceForSwapping, _):
            return []

        case .restriction(.validationError(let validationError, let context), _):
            let event = mapValidationError(source: source, validationError: validationError, context: context)
            return event.map { [$0] } ?? []

        case .restriction(.notEnoughAmountForFee(let isFeeCurrency), _) where isFeeCurrency,
             .restriction(.notEnoughAmountForTxValue(_, let isFeeCurrency), _) where isFeeCurrency:
            return []

        case .restriction(.notEnoughAmountForFee, _), .restriction(.notEnoughAmountForTxValue, _):
            let feeBlockchain = source.tokenItem.blockchain

            return [
                .notEnoughFeeForTokenTx(
                    mainTokenName: feeBlockchain.displayName,
                    mainTokenSymbol: feeBlockchain.currencySymbol,
                    blockchainIconAsset: NetworkImageProvider().provide(by: feeBlockchain, filled: true)
                ),
            ]

        case .restriction(.notEnoughReceivedAmount(let minAmount, let tokenSymbol), _):
            return [.notEnoughReceivedAmountForReserve(amountFormatted: "\(minAmount.formatted()) \(tokenSymbol)")]

        case .permissionRequired:
            return [
                .permissionNeeded(
                    providerName: provider?.provider.name ?? "",
                    currencyCode: sourceTokenItemSymbol,
                    analyticsParams: analyticsParams
                ),
            ]

        case .previewCEX(let previewCEX):
            var events: [ExpressNotificationEvent] = []

            if previewCEX.subtractFee.subtractFee > 0 {
                let feeTokenItem = previewCEX.subtractFee.feeTokenItem
                let feeFiatValue = BalanceConverter().convertToFiat(previewCEX.subtractFee.subtractFee, currencyId: feeTokenItem.currencyId ?? "")

                let formatter = BalanceFormatter()
                let cryptoAmountFormatted = formatter.formatCryptoBalance(previewCEX.subtractFee.subtractFee, currencyCode: feeTokenItem.currencySymbol)
                let fiatAmountFormatted = formatter.formatFiatBalance(feeFiatValue)

                let event = ExpressNotificationEvent.feeWillBeSubtractFromSendingAmount(
                    cryptoAmountFormatted: cryptoAmountFormatted,
                    fiatAmountFormatted: fiatAmountFormatted
                )

                events.append(event)
            }

            if let notification = previewCEX.notification {
                let factory = BlockchainSDKNotificationMapper(tokenItem: source.tokenItem)
                let withdrawalNotification = factory.mapToWithdrawalNotificationEvent(notification)
                let event = ExpressNotificationEvent.withdrawalNotificationEvent(withdrawalNotification)
                events.append(event)
            }

            return events

        case .readyToSwap:
            return []
        }
    }

    func mapValidationError(source: any SendSourceToken, validationError: ValidationError, context: ValidationErrorContext) -> ExpressNotificationEvent? {
        let factory = BlockchainSDKNotificationMapper(tokenItem: source.tokenItem)
        let validationErrorEvent = factory.mapToValidationErrorEvent(validationError)
        let event: ExpressNotificationEvent

        switch validationErrorEvent {
        case .invalidNumber:
            return .refreshRequired(title: Localization.commonError, message: validationError.localizedDescription)

        case .insufficientBalance:
            assertionFailure("It has to be mapped to ExpressInteractor.RestrictionType.notEnoughBalanceForSwapping")
            return nil

        case .insufficientBalanceForFee:
            assertionFailure("It has to be mapped to ExpressInteractor.RestrictionType.notEnoughAmountForFee")
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
            return .validationErrorEvent(event: validationErrorEvent, context: context)
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

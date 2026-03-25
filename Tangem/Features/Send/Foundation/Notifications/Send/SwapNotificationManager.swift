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
    private var analyticsServices: ThreadSafeContainer<[UserWalletId: NotificationsAnalyticsService]> = [:]

    private var setupCancellable: AnyCancellable?
    private var analyticsServiceCancellable: AnyCancellable?

    init() {}

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
        case (.success, .failure(ExpressDestinationServiceError.destinationNotFound(let source)), _):
            return [.noDestinationTokens(tokenName: source.name)]

        case (.failure(ExpressDestinationServiceError.sourceNotFound(let destination)), .success, _):
            return [.noDestinationTokens(tokenName: destination.name)]

        // Expected when couldn't load the providers list
        case (_, _, .failure):
            return [.refreshRequired(title: Localization.commonError, message: Localization.commonUnknownError)]

        case (.success, .success, .loaded(let providers, _, _)) where providers.isEmpty:
            return [.unsupportedPair]

        case (.success(let source), .success(let receive), .loaded(_, let selected, let state)):
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
            var events: [SwapNotificationEvent] = []

            if previewCEX.subtractFee.subtractFee > 0 {
                let feeTokenItem = previewCEX.subtractFee.feeTokenItem
                let feeFiatValue = BalanceConverter().convertToFiat(previewCEX.subtractFee.subtractFee, currencyId: feeTokenItem.currencyId ?? "")

                let formatter = BalanceFormatter()
                let cryptoAmountFormatted = formatter.formatCryptoBalance(previewCEX.subtractFee.subtractFee, currencyCode: feeTokenItem.currencySymbol)
                let fiatAmountFormatted = formatter.formatFiatBalance(feeFiatValue)

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

        case .readyToSwap:
            return []
        }
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

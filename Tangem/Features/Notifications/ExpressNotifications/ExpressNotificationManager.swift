//
//  ExpressNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk
import TangemAssets
import TangemExpress
import TangemFoundation
import TangemLocalization

final class ExpressNotificationManager {
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])

    private weak var expressInteractor: ExpressInteractor?
    private weak var delegate: NotificationTapDelegate?
    private var analyticsService: NotificationsAnalyticsService

    private var bag: Set<AnyCancellable> = []

    init(userWalletId: UserWalletId, expressInteractor: ExpressInteractor) {
        self.expressInteractor = expressInteractor
        analyticsService = NotificationsAnalyticsService(userWalletId: userWalletId)

        bind()
    }

    private func bind() {
        expressInteractor?.state
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { $0.setupNotifications(state: $1) }
            .store(in: &bag)

        notificationPublisher
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { manager, notifications in
                manager.analyticsService.sendEventsIfNeeded(for: notifications)
            })
            .store(in: &bag)
    }

    private func setupNotifications(state: ExpressInteractor.State) {
        switch state {
        case .idle:
            notificationInputsSubject.value = []

        case .loading(.refreshRates), .loading(.fee):
            break

        case .loading(.full):
            notificationInputsSubject.value = notificationInputsSubject.value.filter {
                guard let event = $0.settings.event as? ExpressNotificationEvent else {
                    return false
                }

                return !event.removingOnFullLoadingState
            }

        case .requiredRefresh(let occurredError, _):
            Task { await setupNotification(for: occurredError) }

        case .preloadRestriction(let preloadRestrictionType):
            Task { await setupNotification(for: preloadRestrictionType) }

        case .restriction(let restrictions, _, _):
            runTask(in: self) { manager in
                try await manager.setupNotification(for: restrictions)
            }

        case .permissionRequired:
            runTask(in: self) { manager in
                try await manager.setupPermissionRequiredNotification()
            }

        case .readyToSwap:
            notificationInputsSubject.value = []

        case .previewCEX(let preview, _, _):
            var inputs: [NotificationViewInput] = []

            if let feeWillBeSubtractFromSendingAmount = setupFeeWillBeSubtractFromSendingAmountNotification(subtractFee: preview.subtractFee) {
                inputs.append(feeWillBeSubtractFromSendingAmount)
            }

            if let source = expressInteractor?.getSource().value, let notification = preview.notification {
                inputs.append(
                    setupWithdrawalInput(source: source, notification: notification)
                )
            }

            notificationInputsSubject.value = inputs
        }
    }

    private func setupNotification(for restrictions: ExpressInteractor.PreloadRestrictionType) async {
        let event: ExpressNotificationEvent

        switch restrictions {
        case .noSourceTokens(let destinationTokenItem):
            event = .noDestinationTokens(tokenName: destinationTokenItem.name)
        case .noDestinationTokens(let sourceTokenItem):
            event = .noDestinationTokens(tokenName: sourceTokenItem.name)
        case .pairNotAvailable(let sourceTokenItem, let destinationTokenItem):
            event = .pairNotAvailable(sourceTokenName: sourceTokenItem.name, destinationTokenName: destinationTokenItem.name)
        }

        let notificationsFactory = NotificationsFactory()
        let notification = notificationsFactory.buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotification(with: id, action: actionType)
        }

        await updateNotificationInputs([notification])
    }

    private func setupNotification(for error: Error) async {
        let event: ExpressNotificationEvent

        switch error {
        case let occurredError as ExpressAPIError:
            // For only a express error we use "Service temporary unavailable"
            // or "Selected pair temporarily unavailable" depending on the error code.
            var analyticsParams: [Analytics.ParameterKey: String] = [
                .errorCode: "\(occurredError.errorCode.rawValue)",
            ]

            if let sender = expressInteractor?.getSource().value {
                analyticsParams[.sendToken] = sender.tokenItem.currencySymbol
            }

            if let provider = expressInteractor?.getState().context?.provider.name {
                analyticsParams[.provider] = provider
            }

            if let receiveToken = expressInteractor?.getDestination()?.tokenItem.currencySymbol {
                analyticsParams[.receiveToken] = receiveToken
            }

            event = .refreshRequired(
                title: occurredError.localizedTitle,
                message: occurredError.localizedMessage,
                expressErrorCode: occurredError.errorCode,
                analyticsParams: analyticsParams
            )
        default:
            event = .refreshRequired(title: Localization.commonError, message: Localization.commonUnknownError)
        }

        let notificationsFactory = NotificationsFactory()
        let notification = notificationsFactory.buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotification(with: id, action: actionType)
        }

        await updateNotificationInputs([notification])
    }

    private func setupNotification(for restrictions: ExpressInteractor.RestrictionType) async throws {
        guard let interactor = expressInteractor else { return }

        let event: ExpressNotificationEvent

        switch restrictions {
        case .tooSmallAmountForSwapping(let minAmount):
            let sourceTokenItemSymbol = try interactor.getSourceWallet().tokenItem.currencySymbol
            event = .tooSmallAmountToSwap(minimumAmountText: "\(minAmount) \(sourceTokenItemSymbol)")
        case .tooBigAmountForSwapping(let maxAmount):
            let sourceTokenItemSymbol = try interactor.getSourceWallet().tokenItem.currencySymbol
            event = .tooBigAmountToSwap(maximumAmountText: "\(maxAmount) \(sourceTokenItemSymbol)")
        case .hasPendingTransaction:
            let sourceTokenItemSymbol = try interactor.getSourceWallet().tokenItem.currencySymbol
            event = .hasPendingTransaction(symbol: sourceTokenItemSymbol)
        case .hasPendingApproveTransaction:
            event = .hasPendingApproveTransaction
        case .notEnoughBalanceForSwapping:
            await updateNotificationInputs([])
            return
        case .validationError(let error, let context):
            let sender = try interactor.getSourceWallet()
            setupNotification(source: sender, validationError: error, context: context)
            return
        case .notEnoughAmountForFee(let isFeeCurrency), .notEnoughAmountForTxValue(_, let isFeeCurrency):
            guard !isFeeCurrency else {
                await updateNotificationInputs([])
                return
            }

            let sender = try interactor.getSourceWallet()
            let notEnoughFeeForTokenTxEvent = makeNotEnoughFeeForTokenTx(feeBlockchain: sender.feeTokenItem.blockchain)
            event = notEnoughFeeForTokenTxEvent
        case .notEnoughReceivedAmount(let minAmount, let tokenSymbol):
            event = .notEnoughReceivedAmountForReserve(amountFormatted: "\(minAmount.formatted()) \(tokenSymbol)")
        }

        let notificationsFactory = NotificationsFactory()
        let notification = notificationsFactory.buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotification(with: id, action: actionType)
        }

        await updateNotificationInputs([notification])
    }

    private func setupNotification(source: any ExpressInteractorSourceWallet, validationError: ValidationError, context: ValidationErrorContext) {
        let factory = BlockchainSDKNotificationMapper(tokenItem: source.tokenItem)
        let validationErrorEvent = factory.mapToValidationErrorEvent(validationError)
        let event: ExpressNotificationEvent

        switch validationErrorEvent {
        case .invalidNumber:
            event = .refreshRequired(title: Localization.commonError, message: validationError.localizedDescription)

        case .insufficientBalance:
            assertionFailure("It has to be mapped to ExpressInteractor.RestrictionType.notEnoughBalanceForSwapping")
            notificationInputsSubject.value = []
            return

        case .insufficientBalanceForFee:
            assertionFailure("It has to be mapped to ExpressInteractor.RestrictionType.notEnoughAmountForFee")
            notificationInputsSubject.value = []
            return

        case .minimumRestrictAmount:
            // The error will be displayed above the amount input field
            return

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
            event = .validationErrorEvent(event: validationErrorEvent, context: context)
        }

        let notification = NotificationsFactory().buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotification(with: id, action: actionType)
        }

        notificationInputsSubject.value = [notification]
    }

    private func setupPermissionRequiredNotification() async throws {
        guard let interactor = expressInteractor else { return }

        let source = try interactor.getSourceWallet()
        let sourceTokenItem = source.tokenItem
        let selectedProvider = interactor.getState().context?.provider

        var analyticsParams: [Analytics.ParameterKey: String] = [:]
        analyticsParams[.sendToken] = sourceTokenItem.currencySymbol
        analyticsParams[.provider] = selectedProvider?.name
        analyticsParams[.receiveToken] = interactor.getDestination()?.tokenItem.currencySymbol

        let event: ExpressNotificationEvent = .permissionNeeded(
            providerName: selectedProvider?.name ?? "",
            currencyCode: sourceTokenItem.currencySymbol,
            analyticsParams: analyticsParams
        )

        let notificationsFactory = NotificationsFactory()
        let notification = notificationsFactory.buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotification(with: id, action: actionType)
        }

        await updateNotificationInputs([notification])
    }

    /// Updates may be called from async context - hence the @MainActor.
    @MainActor
    private func updateNotificationInputs(_ inputs: [NotificationViewInput]) {
        notificationInputsSubject.value = inputs
    }

    private func setupFeeWillBeSubtractFromSendingAmountNotification(
        subtractFee: ExpressInteractor.SubtractFee
    ) -> NotificationViewInput? {
        guard subtractFee.subtractFee > 0 else {
            return nil
        }

        let feeTokenItem = subtractFee.feeTokenItem
        let feeFiatValue = BalanceConverter().convertToFiat(subtractFee.subtractFee, currencyId: feeTokenItem.currencyId ?? "")

        let formatter = BalanceFormatter()
        let cryptoAmountFormatted = formatter.formatCryptoBalance(subtractFee.subtractFee, currencyCode: feeTokenItem.currencySymbol)
        let fiatAmountFormatted = formatter.formatFiatBalance(feeFiatValue)

        let event = ExpressNotificationEvent.feeWillBeSubtractFromSendingAmount(
            cryptoAmountFormatted: cryptoAmountFormatted,
            fiatAmountFormatted: fiatAmountFormatted
        )

        let notification = NotificationsFactory().buildNotificationInput(for: event)
        return notification
    }

    private func makeNotEnoughFeeForTokenTx(feeBlockchain: Blockchain) -> ExpressNotificationEvent {
        let blockchainIconProvider = NetworkImageProvider()

        return .notEnoughFeeForTokenTx(
            mainTokenName: feeBlockchain.displayName,
            mainTokenSymbol: feeBlockchain.currencySymbol,
            blockchainIconAsset: blockchainIconProvider.provide(by: feeBlockchain, filled: true)
        )
    }

    private func setupWithdrawalInput(source: any ExpressInteractorSourceWallet, notification: WithdrawalNotification) -> NotificationViewInput {
        let factory = BlockchainSDKNotificationMapper(tokenItem: source.tokenItem)
        let withdrawalNotification = factory.mapToWithdrawalNotificationEvent(notification)

        let event = ExpressNotificationEvent.withdrawalNotificationEvent(withdrawalNotification)
        let input = NotificationsFactory().buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotification(with: id, action: actionType)
        }
        return input
    }
}

extension ExpressNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate

        setupNotifications(state: expressInteractor?.getState() ?? .idle)
    }

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}

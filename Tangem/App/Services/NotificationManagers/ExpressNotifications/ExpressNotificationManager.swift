//
//  ExpressNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import struct TangemExpress.ExpressAPIError

class ExpressNotificationManager {
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])

    private weak var expressInteractor: ExpressInteractor?
    private weak var delegate: NotificationTapDelegate?
    private var analyticsService: NotificationsAnalyticsService = .init()

    private var subscription: AnyCancellable?

    init(expressInteractor: ExpressInteractor) {
        self.expressInteractor = expressInteractor

        bind()
    }

    private func bind() {
        subscription = expressInteractor?.state
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: weakify(self, forFunction: ExpressNotificationManager.setupNotifications(for:)))
    }

    private func setupNotifications(for state: ExpressInteractor.State) {
        switch state {
        case .idle:
            notificationInputsSubject.value = []
        case .loading(.refreshRates):
            break
        case .loading(.full):
            notificationInputsSubject.value = notificationInputsSubject.value.filter {
                guard let event = $0.settings.event as? ExpressNotificationEvent else {
                    return false
                }

                return !event.removingOnFullLoadingState
            }
        case .restriction(let restrictions, _):
            setupNotification(for: restrictions)

        case .permissionRequired:
            setupPermissionRequiredNotification()

        case .readyToSwap:
            notificationInputsSubject.value = []

        case .previewCEX(let preview, _):
            notificationInputsSubject.value = []

            setupFeeWillBeSubtractFromSendingAmountNotification(subtractFee: preview.subtractFee)
            setupWithdrawalSuggestion(suggestion: preview.suggestion)
        }
    }

    private func setupNotification(for restrictions: ExpressInteractor.RestrictionType) {
        guard let interactor = expressInteractor else { return }

        let sourceTokenItem = interactor.getSender().tokenItem
        let sourceTokenItemSymbol = sourceTokenItem.currencySymbol
        let event: ExpressNotificationEvent
        let notificationsFactory = NotificationsFactory()

        switch restrictions {
        case .tooSmallAmountForSwapping(let minAmount):
            event = .tooSmallAmountToSwap(minimumAmountText: "\(minAmount) \(sourceTokenItemSymbol)")
        case .tooBigAmountForSwapping(let maxAmount):
            event = .tooBigAmountToSwap(maximumAmountText: "\(maxAmount) \(sourceTokenItemSymbol)")
        case .hasPendingTransaction:
            event = .hasPendingTransaction(symbol: sourceTokenItemSymbol)
        case .hasPendingApproveTransaction:
            event = .hasPendingApproveTransaction
        case .notEnoughBalanceForSwapping:
            notificationInputsSubject.value = []
            return
        case .validationError(let validationError):
            setupNotification(for: validationError)
            return
        case .notEnoughAmountForFee:
            guard let notEnoughFeeForTokenTxEvent = makeNotEnoughFeeForTokenTx(sender: interactor.getSender()) else {
                notificationInputsSubject.value = []
                return
            }

            event = notEnoughFeeForTokenTxEvent
        case .notEnoughReceivedAmount(let minAmount, let tokenSymbol):
            event = .notEnoughReceivedAmountForReserve(amountFormatted: "\(minAmount.formatted()) \(tokenSymbol)")
        case .requiredRefresh(let occurredError as ExpressAPIError):
            // For only a express error we use "Service temporary unavailable"
            event = .refreshRequired(title: Localization.warningExpressRefreshRequiredTitle, message: occurredError.localizedMessage)
        case .requiredRefresh:
            event = .refreshRequired(title: Localization.commonError, message: Localization.commonUnknownError)
        case .noDestinationTokens:
            let sourceTokenItemName = sourceTokenItem.name
            event = .noDestinationTokens(sourceTokenName: sourceTokenItemName)
        }

        let notification = notificationsFactory.buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotificationButton(with: id, action: actionType)
        }
        notificationInputsSubject.value = [notification]
    }

    private func setupNotification(for validationError: ValidationError) {
        guard let interactor = expressInteractor else { return }

        let sourceTokenItem = interactor.getSender().tokenItem
        let sourceTokenItemSymbol = sourceTokenItem.currencySymbol

        let event: ExpressNotificationEvent
        let notificationsFactory = NotificationsFactory()

        switch validationError {
        case .balanceNotFound, .invalidAmount, .invalidFee:
            event = .refreshRequired(title: Localization.commonError, message: validationError.localizedDescription)
        case .amountExceedsBalance, .totalExceedsBalance:
            assertionFailure("It had to mapped to ExpressInteractor.RestrictionType.notEnoughBalanceForSwapping")
            notificationInputsSubject.value = []
            return
        case .feeExceedsBalance:
            assertionFailure("It had to mapped to ExpressInteractor.RestrictionType.notEnoughAmountForFee")
            guard let notEnoughFeeForTokenTxEvent = makeNotEnoughFeeForTokenTx(sender: interactor.getSender()) else {
                notificationInputsSubject.value = []
                return
            }

            event = notEnoughFeeForTokenTxEvent

        case .dustAmount(let minimumAmount), .dustChange(let minimumAmount):
            let amountText = "\(minimumAmount.value) \(sourceTokenItemSymbol)"
            event = .dustAmount(minimumAmountText: amountText, minimumChangeText: amountText)
        case .minimumBalance(let minimumBalance):
            event = .existentialDepositWarning(blockchainName: sourceTokenItem.blockchain.displayName, amount: "\(minimumBalance.value)")
        case .maximumUTXO(let blockchainName, let newAmount, let maxUtxo):
            event = .withdrawalMandatoryAmountChange(amount: newAmount.value, amountFormatted: newAmount.string(), blockchainName: blockchainName, maxUtxo: maxUtxo)
        case .reserve(let amount):
            event = .notEnoughReserveToSwap(maximumAmountText: "\(amount.value)\(sourceTokenItemSymbol)")
        }

        let notification = notificationsFactory.buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotificationButton(with: id, action: actionType)
        }

        notificationInputsSubject.value = [notification]
    }

    private func setupPermissionRequiredNotification() {
        guard let interactor = expressInteractor else { return }

        let sourceTokenItem = interactor.getSender().tokenItem
        let event: ExpressNotificationEvent = .permissionNeeded(currencyCode: sourceTokenItem.currencySymbol)
        let notificationsFactory = NotificationsFactory()

        let notification = notificationsFactory.buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotificationButton(with: id, action: actionType)
        }
        notificationInputsSubject.value = [notification]
    }

    private func setupFeeWillBeSubtractFromSendingAmountNotification(subtractFee: Decimal) {
        let event = ExpressNotificationEvent.feeWillBeSubtractFromSendingAmount

        guard subtractFee > 0 else {
            notificationInputsSubject.value.removeAll(where: { $0.settings.event.id == event.id })
            return
        }

        let factory = NotificationsFactory()
        let notification = factory.buildNotificationInput(for: event)
        notificationInputsSubject.value.appendIfNotContains(notification)
    }

    private func makeNotEnoughFeeForTokenTx(sender: WalletModel) -> ExpressNotificationEvent? {
        guard !sender.isFeeCurrency else {
            return nil
        }

        return .notEnoughFeeForTokenTx(
            mainTokenName: sender.feeTokenItem.blockchain.displayName,
            mainTokenSymbol: sender.feeTokenItem.currencySymbol,
            blockchainIconName: sender.feeTokenItem.blockchain.iconNameFilled
        )
    }

    private func setupWithdrawalSuggestion(suggestion: WithdrawalSuggestion?) {
        switch suggestion {
        case .none:
            break
        case .feeIsTooHigh(let reduceAmountBy):
            let event: ExpressNotificationEvent = .withdrawalOptionalAmountChange(amount: reduceAmountBy.value, amountFormatted: reduceAmountBy.string())
            let notification = NotificationsFactory().buildNotificationInput(for: event) { [weak self] id, actionType in
                self?.delegate?.didTapNotificationButton(with: id, action: actionType)
            }
            notificationInputsSubject.value.appendIfNotContains(notification)
        }
    }
}

public extension ExpressAPIError {
    var localizedMessage: String {
        switch errorCode {
        case .exchangeInternalError:
            return Localization.expressErrorSwapUnavailable(errorCode.rawValue)
        case .exchangeNotPossibleError:
            return Localization.expressErrorSwapPairUnavailable(errorCode.rawValue)
        case .exchangeProviderNotActiveError, .exchangeProviderNotAvailableError,
             .exchangeProviderProviderInternalError:
            return Localization.expressErrorProviderUnavailable(errorCode.rawValue)
        default:
            return Localization.expressErrorCode(errorCode.localizedDescription)
        }
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

        setupNotifications(for: expressInteractor?.getState() ?? .idle)
    }

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}

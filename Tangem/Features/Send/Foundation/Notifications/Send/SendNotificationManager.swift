//
//  SendNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemFoundation

protocol SendNotificationManagerInput {
    var feeValues: AnyPublisher<[TokenFee], Never> { get }
    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> { get }
    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> { get }

    var bsdkTransactionPublisher: AnyPublisher<BSDKTransaction?, Never> { get }
    var transactionCreationError: AnyPublisher<Error?, Never> { get }
}

protocol SendNotificationManager: NotificationManager {
    func setup(input: SendNotificationManagerInput)
}

class CommonSendNotificationManager {
    private let tokenItem: TokenItem
    private let withdrawalNotificationProvider: WithdrawalNotificationProvider?

    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private var bag: Set<AnyCancellable> = []
    private let analyticsService: NotificationsAnalyticsService
    private weak var delegate: NotificationTapDelegate?

    init(
        userWalletId: UserWalletId,
        tokenItem: TokenItem,
        withdrawalNotificationProvider: WithdrawalNotificationProvider?
    ) {
        self.tokenItem = tokenItem
        self.withdrawalNotificationProvider = withdrawalNotificationProvider
        analyticsService = NotificationsAnalyticsService(userWalletId: userWalletId)
    }
}

// MARK: - Bind

private extension CommonSendNotificationManager {
    func bind(input: SendNotificationManagerInput) {
        notificationPublisher
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { manager, notifications in
                manager.analyticsService.sendEventsIfNeeded(for: notifications)
            })
            .store(in: &bag)

        input.selectedTokenFeePublisher
            .filter { !$0.value.isLoading }
            .withWeakCaptureOf(self)
            .sink { manager, fee in
                manager.updateNetworkFeeUnreachable(error: fee.value.error)
            }
            .store(in: &bag)

        Publishers.CombineLatest(
            input.selectedTokenFeePublisher,
            input.feeValues.removeDuplicates(),
        )
        .sink { [weak self] selectedFee, loadedFeeValues in
            self?.updateCustomFee(selectedFee: selectedFee, feeValues: loadedFeeValues)
        }
        .store(in: &bag)

        Publishers.CombineLatest(
            input.selectedTokenFeePublisher,
            input.isFeeIncludedPublisher.removeDuplicates(),
        )
        .sink { [weak self] tokenFee, isFeeIncluded in
            self?.updateFeeInclusionEvent(isFeeIncluded: isFeeIncluded, tokenFee: tokenFee)
        }
        .store(in: &bag)

        input.transactionCreationError
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { manager, error in
                manager.updateNotification(error: error)
            }
            .store(in: &bag)

        if let withdrawalNotificationProvider {
            input
                .bsdkTransactionPublisher
                .withWeakCaptureOf(self)
                .map { manager, transaction in
                    transaction.flatMap {
                        withdrawalNotificationProvider.withdrawalNotification(amount: $0.amount, fee: $0.fee)
                    }
                }
                .withWeakCaptureOf(self)
                .sink { manager, notification in
                    manager.updateWithdrawalNotification(notification: notification)
                }
                .store(in: &bag)
        }
    }
}

// MARK: - Fee

private extension CommonSendNotificationManager {
    func updateNetworkFeeUnreachable(error: Error?) {
        switch error {
        case .none:
            hideAllNotification { $0.isNetworkFeeUnreachable }
        case .some(SuiError.oneSuiCoinIsRequiredForTokenTransaction):
            updateNotification(error: error)
        case .some(BlockchainSdkError.accountNotActivated):
            show(notification: .accountNotActivated(assetName: tokenItem.name))
        case .some:
            show(notification: .networkFeeUnreachable)
        }
    }

    func updateCustomFee(selectedFee: TokenFee, feeValues: [TokenFee]) {
        switch (selectedFee.option, selectedFee.value) {
        case (.custom, .success(let customFee)):
            updateCustomFeeTooLow(
                customFee: customFee,
                lowestFee: feeValues.first(where: { $0.option == .slow })?.value.value
            )

            updateCustomFeeTooHigh(
                customFee: customFee,
                highestFee: feeValues.first(where: { $0.option == .fast })?.value.value
            )

        default:
            hideAllNotification { event in
                switch event {
                case .customFeeTooLow, .customFeeTooHigh:
                    return true
                default:
                    return false
                }
            }
        }
    }

    func updateCustomFeeTooLow(customFee: Fee, lowestFee: Fee?) {
        if let lowestFee, customFee.amount.value < lowestFee.amount.value {
            show(notification: .customFeeTooLow)
        } else {
            hideAllNotification { $0.isCustomFeeTooLow }
        }
    }

    func updateCustomFeeTooHigh(customFee: Fee, highestFee: Fee?) {
        let magnitudeTrigger: Decimal = 5

        if let highestFee, customFee.amount.value > highestFee.amount.value * magnitudeTrigger {
            let highFeeOrder = customFee.amount.value / highestFee.amount.value
            let highFeeOrderOfMagnitude = highFeeOrder.intValue(roundingMode: .plain)

            show(notification: .customFeeTooHigh(orderOfMagnitude: highFeeOrderOfMagnitude))
        } else {
            hideAllNotification { $0.isCustomFeeTooHigh }
        }
    }

    func updateFeeInclusionEvent(isFeeIncluded: Bool, tokenFee: TokenFee) {
        switch tokenFee.value {
        case .success(let fee) where isFeeIncluded:
            let feeCryptoValue = fee.amount.value
            let feeFiatValue = tokenFee.tokenItem.currencyId.flatMap {
                BalanceConverter().convertToFiat(feeCryptoValue, currencyId: $0)
            }

            let formatter = BalanceFormatter()
            let feeCurrencySymbol = tokenFee.tokenItem.currencySymbol
            let cryptoAmountFormatted = formatter.formatCryptoBalance(feeCryptoValue, currencyCode: feeCurrencySymbol)
            let fiatAmountFormatted = formatter.formatFiatBalance(feeFiatValue)

            show(notification: .feeWillBeSubtractFromSendingAmount(
                cryptoAmountFormatted: cryptoAmountFormatted,
                fiatAmountFormatted: fiatAmountFormatted,
                amountCurrencySymbol: feeCurrencySymbol
            ))
        default:
            hideFeeWillBeSubtractedNotification()
        }
    }

    private func hideFeeWillBeSubtractedNotification() {
        hideAllNotification { $0.isFeeWillBeSubtractFromSendingAmount }
    }
}

// MARK: - ValidationError

private extension CommonSendNotificationManager {
    func shouldShowWithdrawal(notification: WithdrawalNotificationEvent) -> Bool {
        switch notification {
        case .cardanoWillBeSendAlongToken, .reduceAmountBecauseFeeIsTooHigh:
            return true
        case .tronWillBeSendTokenFeeDescription:
            if AppSettings.shared.tronWarningWithdrawTokenDisplayed < 3 {
                AppSettings.shared.tronWarningWithdrawTokenDisplayed += 1
                return true
            } else {
                return false
            }
        }
    }

    func updateWithdrawalNotification(notification: WithdrawalNotification?) {
        switch notification {
        case .none:
            hideAllNotification { $0.isWithdrawalNotificationEvent }
        case .some(let suggestion):
            let factory = BlockchainSDKNotificationMapper(tokenItem: tokenItem)
            let withdrawalNotification = factory.mapToWithdrawalNotificationEvent(suggestion)

            guard shouldShowWithdrawal(notification: withdrawalNotification) else {
                return
            }

            show(notification: .withdrawalNotificationEvent(withdrawalNotification))
        }
    }

    func updateNotification(error: Error?) {
        switch error {
        case .none:
            hideAllValidationErrorEvent()
        case let validationError as ValidationError:
            let factory = BlockchainSDKNotificationMapper(tokenItem: tokenItem)
            let validationErrorEvent = factory.mapToValidationErrorEvent(validationError)

            switch validationErrorEvent {
            case .remainingAmountIsLessThanRentExemption,
                 .sendingAmountIsLessThanRentExemption:
                hideFeeWillBeSubtractedNotification()
                fallthrough
            case .dustRestriction,
                 .insufficientBalance,
                 .insufficientBalanceForFee,
                 .existentialDeposit,
                 .amountExceedMaximumUTXO,
                 .cardanoCannotBeSentBecauseHasTokens,
                 .cardanoInsufficientBalanceToSendToken,
                 .notEnoughMana,
                 .manaLimit,
                 .koinosInsufficientBalanceToSendKoin,
                 .insufficientAmountToReserveAtDestination,
                 .minimumRestrictAmount,
                 .destinationMemoRequired,
                 .noTrustlineAtDestination:
                show(notification: .validationErrorEvent(validationErrorEvent))
            case .invalidNumber:
                hideAllValidationErrorEvent()
            }
        case .some(SuiError.oneSuiCoinIsRequiredForTokenTransaction):
            let currencySymbol = tokenItem.blockchain.currencySymbol
            show(notification: .oneSuiCoinIsRequiredForTokenTransaction(currencySymbol: currencySymbol))
        case .some(let error):
            AppLogger.error("Transaction error will not show to user", error: error)
            hideAllValidationErrorEvent()
        }
    }
}

// MARK: - Show/Hide

private extension CommonSendNotificationManager {
    func show(notification event: SendNotificationEvent) {
        var buttonAction: NotificationView.NotificationButtonTapAction?

        if event.buttonAction != nil {
            buttonAction = { [weak self] id, actionType in
                self?.delegate?.didTapNotification(with: id, action: actionType)
            }
        }

        let dismissAction: NotificationView.NotificationAction = { [weak self] id in
            self?.notificationInputsSubject.value.removeAll {
                if let sendNotificationEvent = $0.settings.event as? SendNotificationEvent {
                    return sendNotificationEvent.isEqualByRawCaseIdentifier(to: event)
                }

                return false
            }
        }

        let input = NotificationsFactory().buildNotificationInput(
            for: event,
            buttonAction: buttonAction,
            dismissAction: dismissAction
        )

        let index = notificationInputsSubject.value.firstIndex(where: {
            if let sendNotificationEvent = $0.settings.event as? SendNotificationEvent {
                return sendNotificationEvent.isEqualByRawCaseIdentifier(to: event)
            }

            return false
        })

        if let index {
            notificationInputsSubject.value[index] = input
        } else {
            notificationInputsSubject.value.append(input)
        }
    }

    func hideAllValidationErrorEvent() {
        hideAllNotification { $0.isValidationErrorEvent }
    }

    func hideAllNotification(where shouldBeRemoved: (SendNotificationEvent) -> Bool) {
        notificationInputsSubject.value.removeAll(where: { input in
            guard let event = input.settings.event as? SendNotificationEvent else {
                return false
            }

            return shouldBeRemoved(event)
        })
    }
}

// MARK: - SendNotificationManager

extension CommonSendNotificationManager: SendNotificationManager {
    func setup(input: SendNotificationManagerInput) {
        bag.removeAll()

        bind(input: input)
    }

    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate
    }

    func dismissNotification(with id: NotificationViewId) {}
}

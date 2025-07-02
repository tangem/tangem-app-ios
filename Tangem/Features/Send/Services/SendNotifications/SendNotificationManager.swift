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
    var feeValues: AnyPublisher<[SendFee], Never> { get }
    var selectedFeePublisher: AnyPublisher<SendFee, Never> { get }
    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> { get }

    var bsdkTransactionPublisher: AnyPublisher<BSDKTransaction?, Never> { get }
    var transactionCreationError: AnyPublisher<Error?, Never> { get }
}

protocol SendNotificationManager: NotificationManager {
    func setup(input: SendNotificationManagerInput)
}

class CommonSendNotificationManager {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let withdrawalNotificationProvider: WithdrawalNotificationProvider?

    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private var bag: Set<AnyCancellable> = []

    private weak var delegate: NotificationTapDelegate?

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        withdrawalNotificationProvider: WithdrawalNotificationProvider?
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.withdrawalNotificationProvider = withdrawalNotificationProvider
    }
}

// MARK: - Bind

private extension CommonSendNotificationManager {
    func bind(input: SendNotificationManagerInput) {
        input.feeValues
            .filter { !$0.contains { $0.value.isLoading } }
            .withWeakCaptureOf(self)
            .sink { manager, feeValues in
                manager.updateNetworkFeeUnreachable(errors: feeValues.compactMap(\.value.error))
            }
            .store(in: &bag)

        Publishers.CombineLatest(
            input.selectedFeePublisher,
            input.feeValues.filter { !$0.allConforms { $0.value.isLoading } }
        )
        .sink { [weak self] selectedFee, loadedFeeValues in
            self?.updateCustomFee(selectedFee: selectedFee, feeValues: loadedFeeValues)
        }
        .store(in: &bag)

        input.selectedFeePublisher
            .compactMap { $0.value.value?.amount.value }
            .combineLatest(input.isFeeIncludedPublisher)
            .sink { [weak self] feeValue, isFeeIncluded in
                self?.updateFeeInclusionEvent(isFeeIncluded: isFeeIncluded, feeCryptoValue: feeValue)
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
    func updateNetworkFeeUnreachable(errors: [Error]) {
        if !errors.isEmpty {
            if let oneSuiCoinRequiredError = errors.first(where: { ($0 as? SuiError) == .oneSuiCoinIsRequiredForTokenTransaction }) {
                updateNotification(error: oneSuiCoinRequiredError)
                return
            }

            let hasActivationError = errors.contains { error in
                if case WalletError.accountNotActivated = error {
                    return true
                }
                return false
            }
            let notification: SendNotificationEvent = hasActivationError
                ? .accountNotActivated(assetName: tokenItem.name)
                : .networkFeeUnreachable
            show(notification: notification)
        } else {
            hideAllNotification { event in
                if case .networkFeeUnreachable = event {
                    return true
                }

                return false
            }
        }
    }

    func updateCustomFee(selectedFee: SendFee, feeValues: [SendFee]) {
        switch (selectedFee.option, selectedFee.value) {
        case (.custom, .loaded(let customFee)):
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
            hideAllNotification { event in
                if case .customFeeTooLow = event {
                    return true
                }

                return false
            }
        }
    }

    func updateCustomFeeTooHigh(customFee: Fee, highestFee: Fee?) {
        let magnitudeTrigger: Decimal = 5

        if let highestFee, customFee.amount.value > highestFee.amount.value * magnitudeTrigger {
            let highFeeOrder = customFee.amount.value / highestFee.amount.value
            let highFeeOrderOfMagnitude = highFeeOrder.intValue(roundingMode: .plain)

            show(notification: .customFeeTooHigh(orderOfMagnitude: highFeeOrderOfMagnitude))
        } else {
            hideAllNotification { event in
                if case .customFeeTooHigh = event {
                    return true
                }

                return false
            }
        }
    }

    func updateFeeInclusionEvent(isFeeIncluded: Bool, feeCryptoValue: Decimal) {
        let isAmountIsLessThanRentFeeNotificationVisible = notificationInputsSubject.value.contains(where: { input in
            guard let event = input.settings.event as? ValidationErrorEvent else {
                return false
            }
            if case .remainingAmountIsLessThanRentExemption = event {
                return true
            }
            return false
        })
        guard !isAmountIsLessThanRentFeeNotificationVisible else {
            return
        }
        if isFeeIncluded {
            let feeFiatValue = feeTokenItem.currencyId.flatMap { BalanceConverter().convertToFiat(feeCryptoValue, currencyId: $0) }

            let formatter = BalanceFormatter()
            let cryptoAmountFormatted = formatter.formatCryptoBalance(feeCryptoValue, currencyCode: feeTokenItem.currencySymbol)
            let fiatAmountFormatted = formatter.formatFiatBalance(feeFiatValue)

            show(notification: .feeWillBeSubtractFromSendingAmount(
                cryptoAmountFormatted: cryptoAmountFormatted,
                fiatAmountFormatted: fiatAmountFormatted
            ))
        } else {
            hideFeeWillBeSubtractedNotification()
        }
    }

    private func hideFeeWillBeSubtractedNotification() {
        hideAllNotification { event in
            if case .feeWillBeSubtractFromSendingAmount = event {
                return true
            }

            return false
        }
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
            hideAllNotification { event in
                if case .withdrawalNotificationEvent = event {
                    return true
                }

                return false
            }
        case .some(let suggestion):
            let factory = BlockchainSDKNotificationMapper(tokenItem: tokenItem, feeTokenItem: feeTokenItem)
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
            let factory = BlockchainSDKNotificationMapper(tokenItem: tokenItem, feeTokenItem: feeTokenItem)
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
                 .destinationMemoRequired:
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
                $0.settings.id == id
            }
        }

        let input = NotificationsFactory().buildNotificationInput(
            for: event,
            buttonAction: buttonAction,
            dismissAction: dismissAction
        )

        if let index = notificationInputsSubject.value.firstIndex(where: { $0.id == input.id }) {
            notificationInputsSubject.value[index] = input
        } else {
            notificationInputsSubject.value.append(input)
        }
    }

    func hideAllValidationErrorEvent() {
        hideAllNotification { event in
            if case .validationErrorEvent = event {
                return true
            }

            return false
        }
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

//
//  SendNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol SendNotificationManagerInput {
    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> { get }
    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> { get }
}

class SendNotificationManager {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let input: SendNotificationManagerInput
    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private let transactionCreationNotificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private var bag: Set<AnyCancellable> = []

    private var notEnoughFeeConfiguration: TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration {
        TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration(
            transactionAmountTypeName: tokenItem.name,
            feeAmountTypeName: feeTokenItem.name,
            feeAmountTypeCurrencySymbol: feeTokenItem.currencySymbol,
            feeAmountTypeIconName: feeTokenItem.blockchain.iconNameFilled,
            networkName: tokenItem.networkName
        )
    }

    private weak var delegate: NotificationTapDelegate?

    init(tokenItem: TokenItem, feeTokenItem: TokenItem, input: SendNotificationManagerInput) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.input = input
    }

    var buttonAction: NotificationView.NotificationButtonTapAction {
        delegate?.didTapNotificationButton(with:action:) ?? { _, _ in }
    }

    func transactionCreationNotificationPublisher() -> AnyPublisher<[NotificationViewInput], Never> {
        transactionCreationNotificationInputsSubject.eraseToAnyPublisher()
    }

    func notificationPublisher(for location: SendNotificationEvent.Location) -> AnyPublisher<[NotificationViewInput], Never> {
        notificationPublisher
            .map {
                $0.filter { input in
                    let sendNotificationEvent = input.settings.event as? SendNotificationEvent
                    return sendNotificationEvent?.location == location
                }
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private func bind() {
        input
            .feeValues
            .map {
                $0.contains(where: { $0.value.error != nil })
            }
            .sink { [weak self] hasError in
                self?.updateEventVisibility(hasError, event: .networkFeeUnreachable)
            }
            .store(in: &bag)

        #warning("TODO")
        let sendModel = (input as! SendModel)

        sendModel
            .withdrawalSuggestion
            .sink { [weak self] withdrawalSuggestion in
                guard let self else { return }
                switch withdrawalSuggestion {
                case .optionalAmountChange(let newAmount):
                    let event = SendNotificationEvent.withdrawalOptionalAmountChange(amount: newAmount.value, amountFormatted: newAmount.string())
                    updateEventVisibility(true, event: event)
                case .mandatoryAmountChange(let newAmount, let maxUtxos):
                    let event = SendNotificationEvent.withdrawalMandatoryAmountChange(amount: newAmount.value, amountFormatted: newAmount.string(), blockchainName: tokenItem.blockchain.displayName, maxUtxo: maxUtxos)
                    updateEventVisibility(true, event: event)
                case nil:
                    let events = [
                        SendNotificationEvent.withdrawalOptionalAmountChange(amount: .zero, amountFormatted: ""),
                        SendNotificationEvent.withdrawalMandatoryAmountChange(amount: .zero, amountFormatted: "", blockchainName: "", maxUtxo: 0),
                    ]
                    for event in events {
                        updateEventVisibility(false, event: event)
                    }
                }
            }
            .store(in: &bag)

        let loadedFeeValues = sendModel
            .feeValues
            .withWeakCaptureOf(sendModel)
            .compactMap { sendModel, loadingFeeValues -> [FeeOption: Decimal]? in
                if loadingFeeValues.values.contains(where: { $0.isLoading }) {
                    return nil
                }

                return loadingFeeValues.compactMapValues { $0.value?.amount.value }
            }

        let customFeeValue = sendModel
            .customFeePublisher
            .compactMap {
                $0?.amount.value
            }

        // These are triggered when no custom fee is entered
        Publishers.CombineLatest(loadedFeeValues, customFeeValue)
            .sink { [weak self] loadedFeeValues, customFee in
                guard
                    let lowestFee = loadedFeeValues[.slow],
                    let highestFee = loadedFeeValues[.fast]
                else {
                    return
                }

                let tooLow = customFee < lowestFee
                self?.updateEventVisibility(tooLow, event: .customFeeTooLow)

                let highFeeOrderTrigger = 5
                let tooHigh = customFee > (highestFee * Decimal(highFeeOrderTrigger))
                self?.updateEventVisibility(tooHigh, event: .customFeeTooHigh(orderOfMagnitude: highFeeOrderTrigger))
            }
            .store(in: &bag)

        input
            .isFeeIncludedPublisher
            .sink { [weak self] isFeeIncluded in
                self?.updateEventVisibility(isFeeIncluded, event: .feeCoverage)
            }
            .store(in: &bag)

        sendModel
            .transactionCreationError
            .map {
                ($0 as? TransactionErrors)?.errors ?? []
            }
            .withWeakCaptureOf(self)
            .map { (self, transactionErrors) -> [NotificationViewInput] in
                let factory = NotificationsFactory()
                return transactionErrors
                    .compactMap {
                        guard let notificationEvent = self.notificationEvent(from: $0) else { return nil }
                        return factory.buildNotificationInput(for: notificationEvent, buttonAction: self.buttonAction) { [weak self] settingsId in
                            self?.dismissAction(with: settingsId)
                        }
                    }
            }
            .sink { [weak self] in
                self?.transactionCreationNotificationInputsSubject.send($0)
            }
            .store(in: &bag)
    }

    private func dismissAction(with settingsId: NotificationViewId) {
        notificationInputsSubject.value.removeAll {
            $0.settings.id == settingsId
        }
    }

    private func updateEventVisibility(_ visible: Bool, event: SendNotificationEvent) {
        if visible {
            if !notificationInputsSubject.value.contains(where: { $0.settings.event.hashValue == event.hashValue }) {
                let input = NotificationsFactory().buildNotificationInput(for: event, buttonAction: buttonAction) { [weak self] id in
                    self?.dismissAction(with: id)
                }
                notificationInputsSubject.value.append(input)
            }
        } else {
            notificationInputsSubject.value.removeAll { ($0.settings.event as? SendNotificationEvent)?.id == event.id }
        }
    }

    private func notificationEvent(from transactionError: TransactionError) -> SendNotificationEvent? {
        switch transactionError {
        case .dustAmount(let minimumAmount), .dustChange(let minimumAmount):
            return SendNotificationEvent.minimumAmount(value: minimumAmount.string())
        case .totalExceedsBalance:
            return .totalExceedsBalance(configuration: notEnoughFeeConfiguration)
        case .feeExceedsBalance:
            return .feeExceedsBalance(configuration: notEnoughFeeConfiguration)
        case .minimumBalance(let minimumBalance):
            return .existentialDeposit(amountFormatted: minimumBalance.string())
        default:
            return nil
        }
    }
}

extension SendNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value + transactionCreationNotificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        Publishers.CombineLatest(notificationInputsSubject, transactionCreationNotificationInputsSubject)
            .map {
                $0 + $1
            }
            .eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate
        bind()
    }

    func dismissNotification(with id: NotificationViewId) {}
}

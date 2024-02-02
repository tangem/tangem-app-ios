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
        let loadedFeeValues = sendModel
            .feeValues
            .compactMap { loadingFeeValues -> [Decimal]? in
                if loadingFeeValues.values.contains(where: { $0.isLoading }) {
                    return nil
                }

                return loadingFeeValues.values.compactMap { $0.value?.amount.value }
            }

        let customFeeValue = sendModel
            .customFeePublisher
            .compactMap {
                $0?.amount.value
            }

        Publishers.CombineLatest(loadedFeeValues, customFeeValue)
            .sink { [weak self] loadedFees, customFee in
                guard
                    let lowestFee = loadedFees.first,
                    let highestFee = loadedFees.last
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

        #warning("TODO")

        sendModel
            .feeError
            .sink { [weak self] feeError in
                guard
                    let self,
                    !sendModel.feeChargedInSameCurrency
                else {
                    return
                }

                let feeExceedsBalance = ((feeError as? TransactionError) == TransactionError.feeExceedsBalance)
                let configuration = TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration(
                    transactionAmountTypeName: tokenItem.name,
                    feeAmountTypeName: feeTokenItem.name,
                    feeAmountTypeCurrencySymbol: feeTokenItem.currencySymbol,
                    feeAmountTypeIconName: feeTokenItem.blockchain.iconNameFilled,
                    networkName: tokenItem.networkName
                )
                updateEventVisibility(feeExceedsBalance, event: .feeExceedsBalance(configuration: configuration))
            }
            .store(in: &bag)

        sendModel
            .reserveAmountForTransaction
            .sink { [weak self] reserveAmountForTransaction in
                let value = reserveAmountForTransaction?.string() ?? ""
                let visible = reserveAmountForTransaction != nil
                self?.updateEventVisibility(visible, event: .invalidReserve(value: value))
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
                    .compactMap(\.sendNotificationEvent)
                    .map {
                        factory.buildNotificationInput(for: $0, buttonAction: self.buttonAction)
                    }
            }
            .sink { [weak self] in
                self?.transactionCreationNotificationInputsSubject.send($0)
            }
            .store(in: &bag)
    }

    private func updateEventVisibility(_ visible: Bool, event: SendNotificationEvent) {
        if visible {
            if !notificationInputsSubject.value.contains(where: { $0.settings.event.hashValue == event.hashValue }) {
                let input = NotificationsFactory().buildNotificationInput(for: event, buttonAction: buttonAction)
                notificationInputsSubject.value.append(input)
            }
        } else {
            notificationInputsSubject.value.removeAll { $0.settings.event.hashValue == event.hashValue }
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

extension TransactionError {
    var sendNotificationEvent: SendNotificationEvent? {
        switch self {
        case .dustAmount(let minimumAmount), .dustChange(let minimumAmount):
            return SendNotificationEvent.minimumAmount(value: minimumAmount.string())
        default:
            return nil
        }
    }
}

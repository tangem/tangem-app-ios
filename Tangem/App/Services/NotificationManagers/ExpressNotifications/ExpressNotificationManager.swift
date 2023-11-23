//
//  ExpressNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ExpressNotificationManager {
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])

    private weak var expressInteractor: ExpressInteractor?
    private weak var delegate: NotificationTapDelegate?
    private var analyticsService: NotificationsAnalyticsService = .init()

    private var subscription: AnyCancellable?
    private var priceImpactTask: Task<Void, Error>?

    init(expressInteractor: ExpressInteractor) {
        self.expressInteractor = expressInteractor

        bind()
    }

    private func bind() {
        subscription = expressInteractor?.state
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: weakify(self, forFunction: ExpressNotificationManager.setupNotifications(for:)))
    }

    private func setupNotifications(for state: ExpressInteractor.ExpressInteractorState) {
        priceImpactTask?.cancel()
        priceImpactTask = nil

        switch state {
        case .readyToSwap(let swapData, _):
            notificationInputsSubject.value = []
            priceImpactTask = runTask(in: self, code: { manager in
                guard let notification = try await manager.generateHighPriceImpactIfNeeded(
                    fromAmount: swapData.data.fromAmount,
                    toAmount: swapData.data.toAmount
                ) else {
                    return
                }

                manager.notificationInputsSubject.value = [notification]
            })
        case .restriction(let restrictions, let expectedQuote):
            setupNotification(for: restrictions)

            guard let quote = expectedQuote?.quote else {
                return
            }

            priceImpactTask = runTask(in: self, code: { manager in
                guard let notification = try await manager.generateHighPriceImpactIfNeeded(
                    fromAmount: quote.fromAmount,
                    toAmount: quote.expectAmount
                ) else {
                    return
                }

                manager.notificationInputsSubject.value.append(notification)
            })
        case .loading(.full):
            notificationInputsSubject.value = notificationInputsSubject.value.filter {
                guard let event = $0.settings.event as? ExpressNotificationEvent else {
                    return false
                }

                return !event.removingOnFullLoadingState
            }
        case .loading(.refreshRates), .idle:
            break
        }
    }

    private func setupNotification(for restrictions: ExpressInteractor.RestrictionType) {
        guard let interactor = expressInteractor else { return }

        let sourceTokenItem = interactor.getSender().tokenItem
        let sourceNetworkSymbol = sourceTokenItem.blockchain.currencySymbol
        let event: ExpressNotificationEvent
        let notificationsFactory = NotificationsFactory()

        switch restrictions {
        case .notEnoughAmountForSwapping(let minAmount):
            event = .notEnoughAmountToSwap(minimumAmountText: "\(minAmount) \(sourceNetworkSymbol)")
        case .permissionRequired:
            event = .permissionNeeded(currencyCode: sourceNetworkSymbol)
        case .hasPendingTransaction:
            event = .hasPendingTransaction
        case .notEnoughBalanceForSwapping:
            notificationInputsSubject.value = []
            return
        case .notEnoughAmountForFee:
            guard sourceTokenItem.isToken else {
                notificationInputsSubject.value = []
                return
            }

            event = .notEnoughFeeForTokenTx(mainTokenName: sourceTokenItem.blockchain.displayName, mainTokenSymbol: sourceNetworkSymbol, blockchainIconName: sourceTokenItem.blockchain.iconNameFilled)
        case .requiredRefresh(let occurredError):
            // [REDACTED_TODO_COMMENT]
            event = .refreshRequired(title: "Something happened", message: occurredError.localizedDescription)
        case .noDestinationTokens:
            event = .noDestinationTokens(sourceTokenName: sourceNetworkSymbol)
        }

        let notification = notificationsFactory.buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotificationButton(with: id, action: actionType)
        }
        notificationInputsSubject.value = [notification]
    }

    private func generateHighPriceImpactIfNeeded(fromAmount: Decimal, toAmount: Decimal) async throws -> NotificationViewInput? {
        guard
            let sourceCurrencyId = expressInteractor?.getSender().tokenItem.currencyId,
            let destinationCurrencyId = expressInteractor?.getDestination()?.tokenItem.currencyId
        else {
            return nil
        }

        let priceImpactCalculator = HighPriceImpactCalculator(sourceCurrencyId: sourceCurrencyId, destinationCurrencyId: destinationCurrencyId)

        let isHighPriceImpact = try await priceImpactCalculator.isHighPriceImpact(
            converting: fromAmount,
            to: toAmount
        )

        if Task.isCancelled {
            return nil
        }

        guard isHighPriceImpact else {
            return nil
        }

        let factory = NotificationsFactory()
        let notification = factory.buildNotificationInput(for: .highPriceImpact)
        return notification
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

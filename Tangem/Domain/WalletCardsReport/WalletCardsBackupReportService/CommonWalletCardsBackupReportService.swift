//
//  CommonWalletCardsBackupReportService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import TangemFoundation
import TangemNetworkUtils

final class CommonWalletCardsBackupReportService {
    private let repository: WalletCardsBackupReportRepository
    private let apiService: TangemApiService
    private let userWalletRepository: UserWalletRepository
    private let savedCardsCollector: WalletCardsSavedCardsCollector
    private let reachabilityProvider: NetworkReachabilityProvider
    private let reportsPreviouslySavedWallets: Bool
    private var deliveryTask: Task<Void, Never>?
    private var savedCardsSubscription: AnyCancellable?

    init(
        reachabilityProvider: NetworkReachabilityProvider = CommonNetworkReachabilityProvider(),
        reportsPreviouslySavedWallets: Bool = FeatureProvider.isAvailable(.walletCardsBackupReportOnLogin),
        repository: WalletCardsBackupReportRepository = InjectedValues[\.walletCardsBackupReportRepository],
        apiService: TangemApiService = InjectedValues[\.tangemApiService],
        userWalletRepository: UserWalletRepository = InjectedValues[\.userWalletRepository]
    ) {
        self.reachabilityProvider = reachabilityProvider
        self.reportsPreviouslySavedWallets = reportsPreviouslySavedWallets
        self.repository = repository
        self.apiService = apiService
        self.userWalletRepository = userWalletRepository
        savedCardsCollector = WalletCardsSavedCardsCollector(userWalletRepository: userWalletRepository)
    }

    deinit {
        deliveryTask?.cancel()
    }
}

// MARK: - WalletCardsBackupReportService

extension CommonWalletCardsBackupReportService: WalletCardsBackupReportService {
    /// Subscribing at launch rather than on the first report is what makes a report left over from a previous
    /// session reach the back end without waiting for another card to be scanned.
    func initialize() {
        bind()
        bindPreviouslySavedWallets()
    }

    func reportCard(_ card: WalletCardsCurrentlyProcessedCard, primaryCardId: String) {
        repository.store(card: card, primaryCardId: primaryCardId, error: nil)
    }

    func reportFailure(_ card: WalletCardsCurrentlyProcessedCard, primaryCardId: String, error: TangemSdkError) {
        repository.store(card: card, primaryCardId: primaryCardId, error: error)
    }
}

// MARK: - Delivery

private extension CommonWalletCardsBackupReportService {
    func bindPreviouslySavedWallets() {
        guard reportsPreviouslySavedWallets else { return }

        savedCardsSubscription = savedCardsCollector.incompleteBackupCardsPublisher
            .withWeakCaptureOf(self)
            .sink { service, cards in
                for card in cards {
                    service.repository.storePreviouslySavedCardIfNeeded(card)
                }
            }
    }

    func bind() {
        let reportChanges = repository.pendingReportsPublisher
            .map(\.last?.id)
            .removeDuplicates()
            .map { _ in () }
        let walletEvents = userWalletRepository.eventProvider
            .filter { event in
                switch event {
                case .unlocked, .unlockedWallet: true
                default: false
                }
            }
            .map { _ in () }
        let deliveryTriggers = Publishers.CombineLatest(
            reachabilityProvider.isReachablePublisher.removeDuplicates(),
            Publishers.Merge(reportChanges, walletEvents),
        )
        .filter { isReachable, _ in
            isReachable
        }

        // A single consumer keeps passes sequential, so the same cards can't be sent twice.
        deliveryTask = Task { [weak self] in
            for await _ in await deliveryTriggers.values_ {
                await self?.deliverPendingReports()
            }
        }
    }

    func deliverPendingReports() async {
        while let report = repository.oldestPendingReport {
            switch await deliver(report: report) {
            case .delivered:
                repository.removePendingReport(report, wasDelivered: true)
            case .refused:
                repository.removePendingReport(report, wasDelivered: false)
            case .postponed:
                return
            }
        }
    }

    func deliver(report: WalletCardsWaitingDeliveryBackupCards) async -> DeliveryResult {
        let request = WalletCardsDTO.Request(
            cards: report.cards.map(mapToDTO),
            usedSeed: report.isImported
        )

        do {
            try await apiService.saveWalletCards(userWalletId: report.userWalletId, cards: request)
            WalletCardsReporterLogger.info("Delivered \(report.cards.count) card(s) of a wallet")
            return .delivered
        } catch where error.isRefusedByBackEnd {
            WalletCardsReporterLogger.error("The back end refused the wallet cards backup report", error: error)
            return .refused
        } catch {
            WalletCardsReporterLogger.error("Couldn't deliver the wallet cards backup report", error: error)
            return .postponed
        }
    }

    func mapToDTO(_ card: WalletCardsBackupCard) -> WalletCardsDTO.Card {
        WalletCardsDTO.Card(
            cardId: card.cardId,
            cardPublicKey: card.cardPublicKey.hexString,
            // A card whose position is unknown, like one added with its wallet, goes without a role so the back end
            // keeps the stored one.
            role: card.role?.wireValue,
            backupStatus: card.backupStatus?.rawValue,
            curves: card.curves.map(\.rawValue),
            errorCode: card.errorCode?.description,
            errorMessage: card.errorMessage
        )
    }
}

// MARK: - DeliveryResult

private extension CommonWalletCardsBackupReportService {
    enum DeliveryResult {
        case delivered
        case refused
        case postponed
    }
}

// MARK: - Error

private extension Error {
    var isRefusedByBackEnd: Bool {
        guard let statusCode = asMoyaError?.response?.statusCode else {
            return false
        }

        let isRetryableClientError = [408, 429].contains(statusCode)
        return (400 ... 499).contains(statusCode) && !isRetryableClientError
    }
}

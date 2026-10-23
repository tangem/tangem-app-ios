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
    @Injected(\.walletCardsBackupReportRepository)
    private var repository: WalletCardsBackupReportRepository

    @Injected(\.tangemApiService)
    private var apiService: TangemApiService

    private let reachabilityProvider: NetworkReachabilityProvider
    private var deliveryTask: Task<Void, Never>?

    init(reachabilityProvider: NetworkReachabilityProvider = CommonNetworkReachabilityProvider()) {
        self.reachabilityProvider = reachabilityProvider
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
    func bind() {
        let deliveryTriggers = Publishers.CombineLatest(
            reachabilityProvider.isReachablePublisher,
            repository.pendingReportsPublisher.map(\.last?.id),
        )
        .removeDuplicates(by: ==)
        .filter { isReachable, newestReportId in
            isReachable && newestReportId != nil
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
            case .delivered, .refused:
                repository.removePendingReport(report)
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
            // The back end takes only `primary` or `backupN`, so a card seen outside a ceremony — which has no
            // position to report — travels as the primary. Only the payload defaults; the stored role stays
            // unknown.
            role: (card.role ?? .primary).wireValue,
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

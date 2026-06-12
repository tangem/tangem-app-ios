//
//  TangemPayTransactionHistoryService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemVisa
import TangemFoundation
import TangemPay

typealias TangemPayTransactionRecord = TangemPayTransactionHistoryResponse.Transaction

final class TangemPayTransactionHistoryService {
    private let apiService: CustomerInfoManagementService
    private let tangemPayAccount: TangemPayAccount
    private let cacheStorage: TangemPayTransactionHistoryCacheStorage?
    private let customerWalletId: String?
    private let mapper = TangemPayTransactionHistoryMapper()

    private let stateSubject = CurrentValueSubject<TransactionsListView.State, Never>(.loading)
    private let taskProcessor = SingleTaskProcessor<Void, Never>()
    private var bag = Set<AnyCancellable>()

    @MainActor
    private(set) var reachedEndOfHistoryList: Bool = false

    @MainActor
    private(set) var records: [TangemPayTransactionRecord] = []

    init(
        apiService: CustomerInfoManagementService,
        tangemPayAccount: TangemPayAccount,
        cacheStorage: TangemPayTransactionHistoryCacheStorage? = nil,
        customerWalletId: String? = nil,
        isTangemPayUnavailablePublisher: AnyPublisher<Bool, Never>
    ) {
        self.apiService = apiService
        self.tangemPayAccount = tangemPayAccount
        self.cacheStorage = cacheStorage
        self.customerWalletId = customerWalletId

        Task { @MainActor [weak self] in
            self?.applyCachedRecordsIfNeeded()
        }

        isTangemPayUnavailablePublisher
            .filter { $0 }
            .removeDuplicates()
            .receiveOnMain()
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.applyCachedRecordsIfNeeded()
                }
            }
            .store(in: &bag)

        bindCardNameUpdates()
    }

    private func bindCardNameUpdates() {
        tangemPayAccount.cardsPublisher
            .map { cards in
                Publishers.MergeMany(cards.map { card in
                    card.displayNamePublisher.map { _ in () }.eraseToAnyPublisher()
                })
            }
            .switchToLatest()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { service, _ in
                Task { @MainActor in
                    service.reformatCurrentRecordsIfPossible()
                }
            }
            .store(in: &bag)
    }

    @MainActor
    private func reformatCurrentRecordsIfPossible() {
        guard !records.isEmpty else { return }
        stateSubject.send(.loaded(mapper.formatTransactions(records, cardNameByCardId: currentCardNameMap())))
    }

    private func loadCachedRecords() -> [TangemPayTransactionRecord]? {
        guard let cacheStorage, let customerWalletId else { return nil }
        return cacheStorage.cachedTransactions(customerWalletId: customerWalletId)
    }

    @MainActor
    private func applyCachedRecordsIfNeeded() {
        guard records.isEmpty, let cached = loadCachedRecords(), !cached.isEmpty else {
            return
        }
        records = cached
        stateSubject.send(.loaded(mapper.formatTransactions(records, cardNameByCardId: currentCardNameMap())))
    }

    @MainActor
    private func storeCacheIfPossible() {
        guard let cacheStorage, let customerWalletId, !records.isEmpty else { return }
        cacheStorage.saveCachedTransactions(records, customerWalletId: customerWalletId)
    }

    private func currentCardNameMap() -> [String: String] {
        let cards = tangemPayAccount.cards
        guard cards.count > 1 else { return [:] }
        return Dictionary(cards.map { ($0.cardId, $0.displayName) }, uniquingKeysWith: { first, _ in first })
    }
}

extension TangemPayTransactionHistoryService {
    var tangemPayTransactionHistoryState: AnyPublisher<TransactionsListView.State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    @MainActor
    func getTransaction(id: String) -> TangemPayTransactionRecord? {
        records.first { $0.id == id }
    }

    @MainActor
    func fetchNextTransactionHistoryPage() -> FetchMore? {
        guard !reachedEndOfHistoryList else {
            return nil
        }

        return FetchMore { [weak self] in
            runTask {
                await self?.taskProcessor.execute { @MainActor [weak self] in
                    guard let self else { return }

                    if records.isEmpty {
                        stateSubject.send(.loading)
                    }

                    do {
                        let newRecords = try await apiService.getTransactionHistory(
                            limit: Constants.numberOfItemsOnPage,
                            cursor: records.last?.id
                        )
                        .transactions

                        records.append(contentsOf: newRecords)
                        reachedEndOfHistoryList = newRecords.count != Constants.numberOfItemsOnPage

                        stateSubject.send(.loaded(mapper.formatTransactions(records, cardNameByCardId: currentCardNameMap())))
                        storeCacheIfPossible()
                    } catch {
                        if records.isEmpty {
                            stateSubject.send(.error(error))
                        }
                    }
                }
            }
        }
    }

    func reloadHistory() async {
        await taskProcessor.execute { @MainActor [weak self] in
            guard let self else { return }

            if records.isEmpty {
                stateSubject.send(.loading)
            }

            do {
                let newRecords = try await apiService.getTransactionHistory(
                    limit: Constants.numberOfItemsOnPage,
                    cursor: nil
                )
                .transactions

                let currentFirstItems = Array(records.prefix(Constants.numberOfItemsOnPage))
                if currentFirstItems != newRecords {
                    records = newRecords
                    reachedEndOfHistoryList = newRecords.count != Constants.numberOfItemsOnPage
                }

                stateSubject.send(.loaded(mapper.formatTransactions(records, cardNameByCardId: currentCardNameMap())))
                storeCacheIfPossible()
            } catch {
                if records.isEmpty {
                    stateSubject.send(.error(error))
                }
            }
        }
    }
}

private extension TangemPayTransactionHistoryService {
    enum Constants {
        static let numberOfItemsOnPage: Int = 20
    }
}

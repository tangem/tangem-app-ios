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
    private let mapper = TangemPayTransactionHistoryMapper()

    private let stateSubject = CurrentValueSubject<TransactionsListView.State, Never>(.loading)
    private let taskProcessor = SingleTaskProcessor<Void, Never>()

    @MainActor
    private(set) var reachedEndOfHistoryList: Bool = false

    @MainActor
    private(set) var records: [TangemPayTransactionRecord] = []

    init(apiService: CustomerInfoManagementService) {
        self.apiService = apiService
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

                        stateSubject.send(.loaded(mapper.formatTransactions(records)))
                    } catch {
                        stateSubject.send(.error(error))
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

                stateSubject.send(.loaded(mapper.formatTransactions(records)))
            } catch {
                stateSubject.send(.error(error))
            }
        }
    }
}

private extension TangemPayTransactionHistoryService {
    enum Constants {
        static let numberOfItemsOnPage: Int = 20
    }
}

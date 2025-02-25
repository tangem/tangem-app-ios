//
//  VisaTransactionHistoryService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemVisa
import TangemFoundation

class VisaTransactionHistoryService {
    private let apiService: VisaTransactionHistoryAPIService
    private let storage: ThreadSafeContainer<[VisaTransactionRecord]> = []
    private let logger = VisaAppLogger(tag: .refreshTokenRepository)

    private let numberOfItemsOnPage: Int = 20
    private var currentOffset = 0
    private var reachEndOfHistoryList = false

    private let stateSubject = CurrentValueSubject<TransactionHistoryServiceState, Never>(.initial)

    init(apiService: VisaTransactionHistoryAPIService) {
        self.apiService = apiService
    }
}

extension VisaTransactionHistoryService {
    var state: TransactionHistoryServiceState {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<TransactionHistoryServiceState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var items: [VisaTransactionRecord] {
        storage.read()
    }

    var canFetchMoreHistory: Bool {
        !reachEndOfHistoryList
    }

    func reloadHistory() async {
        stateSubject.send(.loading)
        let firstItemsInStorage = Array(items.prefix(numberOfItemsOnPage))
        logger.info("Attempting to reload history. Is storage empty: \(firstItemsInStorage.isEmpty)")

        do {
            let itemsOnServer = try await loadRecordsPage(offset: 0)
            if firstItemsInStorage == itemsOnServer {
                logger.info("First \(firstItemsInStorage.count) items in storage are the same as first items on server, no need to update history")
                stateSubject.send(.loaded)
                return
            }

            logger.info("History on server is not same as history on device. Clearing storage and saving new loaded history. New number of items in storage: \(itemsOnServer.count)")
            clearHistory()
            currentOffset = itemsOnServer.count
            reachEndOfHistoryList = currentOffset % numberOfItemsOnPage != 0
            saveRecordsInStorage(records: itemsOnServer)
            AppLogger.info("Reach end of history: \(reachEndOfHistoryList)")
            stateSubject.send(.loaded)
        } catch {
            logger.error("Failed to reload history", error: error)
            stateSubject.send(.failedToLoad(error))
        }
    }

    func loadNextPage() async {
        if reachEndOfHistoryList {
            return
        }

        stateSubject.send(.loading)
        logger.info("Attempting to load next page. Current history offset: \(currentOffset)")
        do {
            let loadedRecords = try await loadRecordsPage(offset: currentOffset)
            reachEndOfHistoryList = loadedRecords.count != numberOfItemsOnPage
            currentOffset += loadedRecords.count
            saveRecordsInStorage(records: loadedRecords)
            logger.info("History loaded sucessfully. Number of new items: \(loadedRecords.count). New offset: \(currentOffset)")
            stateSubject.send(.loaded)
        } catch {
            logger.error("Failed to load tx history page", error: error)
            stateSubject.send(.failedToLoad(error))
        }
    }

    func clearHistory() {
        storage.mutate { value in
            value.removeAll()
        }
    }

    func saveRecordsInStorage(records: [VisaTransactionRecord]) {
        storage.mutate { value in
            value.append(contentsOf: records)
        }
    }
}

private extension VisaTransactionHistoryService {
    func loadRecordsPage(offset: Int) async throws -> [VisaTransactionRecord] {
        logger.info("Attempting to load history page with request, offset: \(offset), numberOfItemsOnPage: \(numberOfItemsOnPage)")
        let response = try await apiService.loadHistoryPage(offset: offset, numberOfItemsPerPage: numberOfItemsOnPage)
        return response.transactions
    }
}

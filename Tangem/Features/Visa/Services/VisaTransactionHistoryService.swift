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
    private let storage: ThreadSafeContainer<[VisaTransactionRecord]> = []
    private var apiService: VisaTransactionHistoryAPIService?

    private let cardId: String?
    private let numberOfItemsOnPage: Int = 20
    private var currentOffset = 0
    private var reachEndOfHistoryList = false
    private var productInstanceId: String?

    private let stateSubject = CurrentValueSubject<TransactionHistoryServiceState, Never>(.initial)

    init(cardId: String?) {
        self.cardId = cardId
    }

    init(
        cardId: String?,
        productInstanceId: String,
        apiService: VisaTransactionHistoryAPIService
    ) {
        self.cardId = cardId
        self.productInstanceId = productInstanceId
        self.apiService = apiService
    }

    func setupApiService(productInstanceId: String, apiService: VisaTransactionHistoryAPIService) {
        VisaLogger.debug("Setup Visa tx history using new service. Product instance id: \(productInstanceId)")
        self.productInstanceId = productInstanceId
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
        VisaLogger.info("Attempting to reload history. Is storage empty: \(firstItemsInStorage.isEmpty)")

        do {
            let itemsOnServer = try await loadRecordsPage(offset: 0)
            if firstItemsInStorage == itemsOnServer {
                VisaLogger.info("First \(firstItemsInStorage.count) items in storage are the same as first items on server, no need to update history")
                stateSubject.send(.loaded)
                return
            }

            VisaLogger.info("History on server is not same as history on device. Clearing storage and saving new loaded history. New number of items in storage: \(itemsOnServer.count)")
            clearHistory()
            currentOffset = itemsOnServer.count
            reachEndOfHistoryList = currentOffset % numberOfItemsOnPage != 0
            saveRecordsInStorage(records: itemsOnServer)
            AppLogger.info("Reach end of history: \(reachEndOfHistoryList)")
            stateSubject.send(.loaded)
        } catch {
            VisaLogger.error("Failed to reload history", error: error)
            stateSubject.send(.failedToLoad(error))
        }
    }

    func loadNextPage() async {
        if reachEndOfHistoryList {
            return
        }

        stateSubject.send(.loading)
        VisaLogger.info("Attempting to load next page. Current history offset: \(currentOffset)")
        do {
            let loadedRecords = try await loadRecordsPage(offset: currentOffset)
            reachEndOfHistoryList = loadedRecords.count != numberOfItemsOnPage
            currentOffset += loadedRecords.count
            saveRecordsInStorage(records: loadedRecords)
            VisaLogger.info("History loaded sucessfully. Number of new items: \(loadedRecords.count). New offset: \(currentOffset)")
            stateSubject.send(.loaded)
        } catch {
            VisaLogger.error("Failed to load tx history page", error: error)
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
        guard
            let apiService,
            let productInstanceId
        else {
            throw "Missing mandatory info"
        }

        VisaLogger.info("Attempting to load history page with request, offset: \(offset), numberOfItemsOnPage: \(numberOfItemsOnPage)")
        let response = try await apiService.loadHistoryPage(
            productInstanceId: productInstanceId,
            cardId: cardId,
            offset: offset,
            numberOfItemsPerPage: numberOfItemsOnPage
        )
        return response.transactions
    }
}

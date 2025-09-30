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
    private let storage: ThreadSafeContainer<[TangemPayTransactionHistoryResponse.Transaction]> = []
    private let apiService: CustomerInfoManagementService

    private let numberOfItemsOnPage: Int = 20
    private var reachEndOfHistoryList = false

    private let stateSubject = CurrentValueSubject<TransactionHistoryServiceState, Never>(.initial)
    private let itemsSubject = CurrentValueSubject<[TangemPayTransactionHistoryResponse.Transaction], Never>([])

    init(apiService: CustomerInfoManagementService) {
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

    var items: [TangemPayTransactionHistoryResponse.Transaction] {
        storage.read()
    }

    var itemsPublisher: AnyPublisher<[TangemPayTransactionHistoryResponse.Transaction], Never> {
        itemsSubject.eraseToAnyPublisher()
    }

    var canFetchMoreHistory: Bool {
        !reachEndOfHistoryList
    }

    func reloadHistory() async {
        stateSubject.send(.loading)
        let firstItemsInStorage = Array(items.prefix(numberOfItemsOnPage))
        VisaLogger.info("Attempting to reload history. Is storage empty: \(firstItemsInStorage.isEmpty)")

        do {
            let itemsOnServer = try await apiService.getTransactionHistory(limit: numberOfItemsOnPage, cursor: nil).transactions
            if firstItemsInStorage == itemsOnServer {
                VisaLogger.info("First \(firstItemsInStorage.count) items in storage are the same as first items on server, no need to update history")
                stateSubject.send(.loaded)
                return
            }

            VisaLogger.info("History on server is not same as history on device. Clearing storage and saving new loaded history. New number of items in storage: \(itemsOnServer.count)")
            clearHistory()
            reachEndOfHistoryList = itemsOnServer.count % numberOfItemsOnPage != 0
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
//        VisaLogger.info("Attempting to load next page. Current history cursor: \(currentOffset)")
        do {
//            VisaLogger.info("Attempting to load history page with request, offset: \(offset), numberOfItemsOnPage: \(numberOfItemsOnPage)")
            let loadedRecords = try await apiService.getTransactionHistory(limit: numberOfItemsOnPage, cursor: storage.read().last?.id).transactions
            reachEndOfHistoryList = loadedRecords.count != numberOfItemsOnPage
            saveRecordsInStorage(records: loadedRecords)
//            VisaLogger.info("History loaded sucessfully. Number of new items: \(loadedRecords.count). New offset: \(currentOffset)")
            stateSubject.send(.loaded)
        } catch {
            VisaLogger.error("Failed to load tx history page", error: error)
            stateSubject.send(.failedToLoad(error))
        }
    }

    func clearHistory() {
        itemsSubject.send([])
        storage.mutate { value in
            value.removeAll()
        }
    }

    func saveRecordsInStorage(records: [TangemPayTransactionHistoryResponse.Transaction]) {
        storage.mutate { value in
            value.append(contentsOf: records)
        }
        itemsSubject.send(storage.read())
    }
}

//
//  MultipleAddressTransactionHistoryService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import TangemFoundation

class MultipleAddressTransactionHistoryService {
    private let tokenItem: TokenItem
    private let addresses: [String]

    private let transactionHistoryProviders: [String: TransactionHistoryProvider]

    private var _state = CurrentValueSubject<TransactionHistoryServiceState, Never>(.initial)
    private let pageSize: Int = 100
    private var cancellable: AnyCancellable?
    private let storage = TransactionRecordsStorage()

    init(
        tokenItem: TokenItem,
        addresses: [String],
        transactionHistoryProviders: [String: TransactionHistoryProvider]
    ) {
        assert(!transactionHistoryProviders.isEmpty, "TransactionHistoryProviders can't be empty")

        self.tokenItem = tokenItem
        self.addresses = addresses
        self.transactionHistoryProviders = transactionHistoryProviders
    }
}

// MARK: - TransactionHistoryService

extension MultipleAddressTransactionHistoryService: TransactionHistoryService {
    var state: TransactionHistoryServiceState {
        _state.value
    }

    var statePublisher: AnyPublisher<TransactionHistoryServiceState, Never> {
        _state.eraseToAnyPublisher()
    }

    var items: [TransactionRecord] {
        get async { await storage.records }
    }

    var canFetchHistory: Bool {
        addresses.contains {
            transactionHistoryProviders[$0]?.canFetchHistory ?? false
        }
    }

    func clearHistory() async {
        cancellable = nil
        transactionHistoryProviders.forEach { _, provider in provider.reset() }
        await cleanStorage()
        AppLogger.info(self, "was reset")
    }

    func update() -> AnyPublisher<Void, Never> {
        Deferred {
            Future { [weak self] promise in
                self?.fetch(result: promise)
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension MultipleAddressTransactionHistoryService {
    /// `Publisher` with the tuple value that contains the address and the history response by the one page
    typealias LoadingPublisher = AnyPublisher<(address: String, response: TransactionHistory.Response), Error>

    func fetch(result: @escaping (Result<Void, Never>) -> Void) {
        if _state.value.isLoading {
            AppLogger.info(self, "already is loading")
            return
        }

        cancellable = nil

        // Collect publishers for the next page if the page is exist
        let publishers: [LoadingPublisher] = addresses.compactMap { address in
            guard canFetchHistory else {
                AppLogger.info(self, "Reached the end of list")
                return nil
            }

            do {
                return try loadTransactionHistory(address: address)
            } catch {
                AppLogger.error(self, "Provider exception. Publisher's set will be nil", error: error)
                return nil
            }
        }

        if publishers.isEmpty {
            AppLogger.info(self, "all addresses reached the end of list")
            result(.success(()))
            return
        }

        AppLogger.info(self, "start loading")
        _state.send(.loading)

        cancellable = Publishers
            .MergeMany(publishers)
            .collect()
            .withWeakCaptureOf(self)
            .asyncMap { service, responses in
                for response in responses {
                    await service.addToStorage(records: response.response.records)
                    AppLogger.info(service, "loaded")
                }
            }
            .receiveCompletion { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?._state.send(.failedToLoad(error))
                    AppLogger.error(self, error: error)
                case .finished:
                    self?._state.send(.loaded)
                }
                result(.success(()))
            }
    }

    func loadTransactionHistory(address: String) throws -> LoadingPublisher {
        let request = TransactionHistory.Request(address: address, amountType: tokenItem.amountType, limit: pageSize)

        guard let provider = transactionHistoryProviders[address] else {
            throw ServiceError.unknownProvider
        }

        return provider
            .loadTransactionHistory(request: request)
            .map { response in
                return (address: address, response: response)
            }
            .eraseToAnyPublisher()
    }

    func cleanStorage() async {
        await storage.clear()
    }

    func addToStorage(records: [TransactionRecord]) async {
        let zippedHashes = await storage.merge(records)
        for hash in zippedHashes {
            AppLogger.info(self, "TransactionRecord with hash: \(hash) was zipped")
        }
    }
}

// MARK: - Auxiliary types

private extension MultipleAddressTransactionHistoryService {
    actor TransactionRecordsStorage {
        private(set) var records: [TransactionRecord] = []

        func clear() {
            records.removeAll()
        }

        /// Merges `newRecords` into the existing collection. For records sharing `(hash, index)`
        /// with an existing entry, sources and destinations are zipped; otherwise the record is appended.
        ///
        /// - Returns: The hashes of records that were zipped with existing entries (for caller-side logging).
        func merge(_ newRecords: [TransactionRecord]) -> [String] {
            var zippedHashes: [String] = []

            for record in newRecords {
                if let index = records.firstIndex(where: { $0.hash == record.hash && $0.index == record.index }) {
                    let oldRecord = records[index]
                    records[index] = TransactionRecord(
                        hash: record.hash,
                        index: record.index,
                        source: oldRecord.source + record.source,
                        destination: oldRecord.destination + record.destination,
                        fee: oldRecord.fee,
                        status: oldRecord.status,
                        isOutgoing: oldRecord.isOutgoing,
                        type: oldRecord.type,
                        date: oldRecord.date,
                        tokenTransfers: oldRecord.tokenTransfers
                    )
                    zippedHashes.append(record.hash)
                } else {
                    records.append(record)
                }
            }

            return zippedHashes
        }
    }
}

extension MultipleAddressTransactionHistoryService {
    enum ServiceError: Error {
        case unknownProvider
    }
}

// MARK: - CustomStringConvertible

extension MultipleAddressTransactionHistoryService: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "name": tokenItem.name,
                "type": tokenItem.isToken ? "Token" : "Coin",
                "requests": transactionHistoryProviders.map { $1.description }.joined(separator: ", "),
            ]
        )
    }
}

//
//  MutipleAddressTransactionHistoryService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import class TangemSwapping.ThreadSafeContainer

class MutipleAddressTransactionHistoryService {
    private let tokenItem: TokenItem
    private let addresses: [String]

    private let transactionHistoryProvider: TransactionHistoryProvider

    private var _state = CurrentValueSubject<TransactionHistoryServiceState, Never>(.initial)
    private var totalPages: [String: Int] = [:]
    private var currentPage: [String: Int] = [:]
    private let pageSize: Int = 20
    private var cancellable: AnyCancellable?
    private var storage: ThreadSafeContainer<[TransactionRecord]> = []

    init(
        tokenItem: TokenItem,
        addresses: [String],
        transactionHistoryProvider: TransactionHistoryProvider
    ) {
        self.tokenItem = tokenItem
        self.addresses = addresses
        self.transactionHistoryProvider = transactionHistoryProvider
    }
}

// MARK: - TransactionHistoryService

extension MutipleAddressTransactionHistoryService: TransactionHistoryService {
    var state: TransactionHistoryServiceState {
        _state.value
    }

    var statePublisher: AnyPublisher<TransactionHistoryServiceState, Never> {
        _state.eraseToAnyPublisher()
    }

    var items: [TransactionRecord] {
        return storage.read()
    }

    var canFetchMore: Bool {
        addresses.contains {
            currentPage[$0, default: 0] < totalPages[$0, default: 0]
        }
    }

    func reset() {
        cancellable = nil
        currentPage = [:]
        totalPages = [:]
        cleanStorage()
        AppLog.shared.debug("\(self) was reset")
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

private extension MutipleAddressTransactionHistoryService {
    typealias LoadingPublisher = AnyPublisher<(address: String, response: TransactionHistory.Response), Error>

    func fetch(result: @escaping (Result<Void, Never>) -> Void) {
        guard !_state.value.isLoading else {
            AppLog.shared.debug("\(self) already is loading")
            return
        }

        cancellable = nil

        let publishers: [LoadingPublisher] = addresses.compactMap { address in
            guard currentPage[address, default: 0] == 0 || canFetchMore else {
                AppLog.shared.debug("Address \(address) in \(self) reached the end of list")
                return nil
            }

            return loadTransactionHistory(address: address)
        }

        guard !publishers.isEmpty else {
            AppLog.shared.debug("\(self) all addresses reached the end of list")
            result(.success(()))
            return
        }

        AppLog.shared.debug("\(self) start loading")
        _state.send(.loading)

        cancellable = Publishers
            .MergeMany(publishers)
            .collect()
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?._state.send(.failedToLoad(error))
                    AppLog.shared.debug("\(String(describing: self)) error: \(error)")
                    result(.success(()))
                case .finished:
                    self?._state.send(.loaded)
                }
            } receiveValue: { [weak self] responses in
                for response in responses {
                    self?.totalPages[response.address, default: 0] = response.response.totalPages
                    self?.currentPage[response.address, default: 0] = response.response.page.number
                    self?.addToStorage(records: response.response.records)

                    AppLog.shared.debug("Address \(response.address) in \(String(describing: self)) loaded")
                }

                result(.success(()))
            }
    }

    func loadTransactionHistory(address: String) -> LoadingPublisher {
        let nextPage = Page(number: currentPage[address, default: 0] + 1, size: pageSize)
        let request = TransactionHistory.Request(address: address, page: nextPage, amountType: tokenItem.amountType)
        return transactionHistoryProvider
            .loadTransactionHistory(request: request)
            .map { (address: address, response: $0) }
            .eraseToAnyPublisher()
    }

    func cleanStorage() {
        storage.mutate { value in
            value.removeAll()
        }
    }

    func addToStorage(records: [TransactionRecord]) {
        storage.mutate { value in
            value += records
        }
    }
}

// MARK: - CustomStringConvertible

extension MutipleAddressTransactionHistoryService: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "name": tokenItem.name,
                "type": tokenItem.isToken ? "Token" : "Coin",
//                "addresses": addresses,
                "totalPages": totalPages,
                "currentPage": currentPage,
            ]
        )
    }
}

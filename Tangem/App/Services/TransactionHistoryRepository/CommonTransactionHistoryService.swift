//
//  CommonTransactionHistoryService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine

class CommonTransactionHistoryService {
    private let blockchain: Blockchain
    private let address: String
    private let repository: TransactionHistoryRepository
    private let transactionHistoryProvider: TransactionHistoryProvider

    private var _state = CurrentValueSubject<TransactionHistoryServiceState, Never>(.initial)
    private var totalPages = 0
    private var currentPage = 0
    private let pageSize: Int = 20
    private var cancellable: AnyCancellable?

    init(
        blockchain: Blockchain,
        address: String,
        repository: TransactionHistoryRepository,
        transactionHistoryProvider: TransactionHistoryProvider
    ) {
        self.blockchain = blockchain
        self.address = address
        self.repository = repository
        self.transactionHistoryProvider = transactionHistoryProvider
    }
}

// MARK: - TransactionHistoryService

extension CommonTransactionHistoryService: TransactionHistoryService {
    var state: TransactionHistoryServiceState {
        _state.value
    }

    var statePublisher: AnyPublisher<TransactionHistoryServiceState, Never> {
        _state.eraseToAnyPublisher()
    }

    var items: [TransactionRecord] {
        return repository.records(blockchain: blockchain)
    }

    var canFetchMore: Bool {
        currentPage < totalPages
    }

    func reset() {
        cancellable = nil
        currentPage = 0
        totalPages = 0
        repository.update(records: [], for: blockchain)
        AppLog.shared.debug("\(self) was reset")
    }

    func update() -> AnyPublisher<Void, Error> {
        Deferred {
            Future<Void, Error> { [weak self] promise in
                self?.fetch(result: promise)
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CommonTransactionHistoryService {
    func fetch(result: @escaping (Result<Void, Error>) -> Void) {
        cancellable = nil

        guard currentPage == 0 || canFetchMore else {
            AppLog.shared.debug("\(self) reached the end of list")
            return
        }

        AppLog.shared.debug("\(self) start loading")
        _state.send(.loading)

        let nextPage = Page(number: currentPage + 1, size: pageSize)
        cancellable = transactionHistoryProvider
            .loadTransactionHistory(address: address, page: nextPage)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?._state.send(.failedToLoad(error))
                    result(.failure(error))
                    AppLog.shared.debug("\(String(describing: self)) error: \(error)")
                case .finished:
                    self?._state.send(.loaded)
                }
            } receiveValue: { [weak self] response in
                guard let self else {
                    return
                }

                totalPages = response.totalPages
                currentPage = response.page.number
                repository.add(records: response.records, for: blockchain)
                AppLog.shared.debug("\(self) loaded")
                result(.success(()))
            }
    }
}

// MARK: - CustomStringConvertible

extension CommonTransactionHistoryService: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "blockchain": blockchain.displayName,
                "address": address,
                "totalPages": totalPages,
                "currentPage": currentPage,
            ]
        )
    }
}

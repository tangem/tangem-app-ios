//
//  WalletTransactionHistoryService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine

class WalletTransactionHistoryService {
    private let blockchain: Blockchain
    private let address: String
    private let mapper: TransactionHistoryMapper
    private let repository: TransactionHistoryRepository
    private let transactionHistoryProvider: TransactionHistoryProvider

    private var _state: CurrentValueSubject<State, Never> = .init(.notLoaded)

    private var totalPages = 0
    private var currentPage = 0
    private let pageSize: Int = 20
    private var cancellable: AnyCancellable?

    var canFetchMore: Bool {
        currentPage < totalPages
    }

    init?(
        blockchain: Blockchain,
        address: String,
        mapper: TransactionHistoryMapper,
        repository: TransactionHistoryRepository
    ) {
        let factory = WalletManagerFactoryProvider().transactionHistoryFactory
        guard let transactionHistoryProvider = factory.makeProvider(for: blockchain) else {
            return nil
        }

        self.blockchain = blockchain
        self.address = address
        self.mapper = mapper
        self.repository = repository
        self.transactionHistoryProvider = transactionHistoryProvider
    }

    func state() -> AnyPublisher<State, Never> {
        _state.eraseToAnyPublisher()
    }

    func items() -> [TransactionListItem] {
        let records = repository.records(blockchain: blockchain)
        return mapper.mapTransactionListItem(from: records)
    }

    func reset() {
        cancellable = nil
        currentPage = 0
        totalPages = 0
        repository.update(records: [], for: blockchain)
    }

    func fetch() {
        cancellable = nil

        guard currentPage == 0 || canFetchMore else {
            AppLog.shared.debug("PagerLoader reach the end of list")
            return
        }

        _state.send(.loading)

        let nextPage = Page(number: currentPage + 1, size: pageSize)
        cancellable = transactionHistoryProvider
            .loadTransactionHistory(address: address, page: nextPage)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?._state.send(.failedToLoad(error))
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
            }
    }
}

extension WalletTransactionHistoryService {
    enum State {
        case notSupported
        case notLoaded
        case loading
        case failedToLoad(Error)
        case loaded
    }
}

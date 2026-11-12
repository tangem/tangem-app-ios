//
//  TronTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class TronTransactionHistoryProvider<Mapper> where
    Mapper: TransactionHistoryMapper,
    Mapper: BlockBookTransactionHistoryTotalPageCountExtractor,
    Mapper.Response == BlockBookAddressResponse,
    Mapper.WalletAddress == String {
    private let blockBookProvider: BlockBookUTXOProvider
    private let mapper: Mapper
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(
        blockBookProvider: BlockBookUTXOProvider,
        mapper: Mapper
    ) {
        self.blockBookProvider = blockBookProvider
        self.mapper = mapper
    }
}

// MARK: - TransactionHistoryProvider protocol conformance

extension TronTransactionHistoryProvider: TransactionHistoryProvider {
    var description: String {
        let snapshot = state { $0 }

        return objectDescription(
            self,
            userInfo: [
                "pageNumber": snapshot.page?.number ?? "nil",
                "totalPageCount": snapshot.totalPageCount,
            ]
        )
    }

    var canFetchHistory: Bool {
        state { state in
            state.page == nil || (state.page?.number ?? Constants.initialPageNumber) < state.totalPageCount
        }
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        guard case .address(let address) = request.key else {
            return .anyFail(error: TransactionHistory.ProviderError.requestKeyNotSupported)
        }

        let (resetToken, page) = state { ($0.resetToken, $0.page) }
        let requestedPageNumber: Int
        if let page {
            requestedPageNumber = page.number + 1
        } else {
            requestedPageNumber = Constants.initialPageNumber
        }

        return Just(
            BlockBookTarget.AddressRequestParameters(
                page: requestedPageNumber,
                pageSize: request.limit,
                details: [.txslight],
                filterType: .init(amountType: request.amountType)
            )
        )
        .withWeakCaptureOf(self)
        .flatMap { historyProvider, parameters in
            return historyProvider
                .blockBookProvider
                .addressData(address: address, parameters: parameters)
        }
        .withWeakCaptureOf(self)
        .tryMap { historyProvider, response in
            let contractAddress = request.amountType.token?.contractAddress
            let totalPageCount = try historyProvider.mapper.extractTotalPageCount(
                from: response,
                contractAddress: contractAddress
            )

            return (response, totalPageCount)
        }
        .map { response, totalPageCount in
            // In some rare cases for some really old addresses (like Binance cold wallet `TMuA6YqfCeX8EhbfYEg5y7S4DqzSJireY9` for example),
            // the returned number of total pages count (`BlockBookAddressResponse.totalPages` property) is greater than
            // the actual number of pages.
            // In such cases we have to manually fix the last received chunk of tx history (actually, a duplicated chunk)
            // and treat it as an empty page.
            //
            // Again, Tron Blockbook is a really terrible API
            if let receivedPageNumber = response.page, receivedPageNumber < requestedPageNumber {
                let fixedResponse = BlockBookAddressResponse(
                    page: requestedPageNumber,
                    totalPages: response.totalPages,
                    itemsOnPage: response.itemsOnPage,
                    address: response.address,
                    balance: response.balance,
                    unconfirmedBalance: response.unconfirmedBalance,
                    unconfirmedTxs: response.unconfirmedTxs,
                    txs: response.txs,
                    nonTokenTxs: response.nonTokenTxs,
                    transactions: [],
                    tokens: response.tokens
                )

                return (fixedResponse, receivedPageNumber)
            }

            return (response, totalPageCount)
        }
        .withWeakCaptureOf(self)
        .tryMap { historyProvider, input in
            let (response, totalPageCount) = input
            let records = try historyProvider.mapper.mapToTransactionRecords(
                response,
                walletAddress: address,
                amountType: request.amountType
            )
            .filter { record in
                historyProvider.shouldBeIncludedInHistory(
                    amountType: request.amountType,
                    record: record
                )
            }

            historyProvider.state { state in
                guard state.resetToken == resetToken else {
                    return
                }

                state.page = TransactionHistoryIndexPage(number: response.page ?? Constants.initialPageNumber)
                state.totalPageCount = totalPageCount
            }

            return TransactionHistory.Response(records: records)
        }
        .eraseToAnyPublisher()
    }

    func reset() {
        state { $0 = State() }
        mapper.reset()
    }
}

// MARK: - Auxiliary types

private extension TronTransactionHistoryProvider {
    struct State {
        /// Changes with every reset, so a response to a request made before the reset can't update the new state.
        let resetToken = UUID()
        var page: TransactionHistoryIndexPage?
        var totalPageCount = 0
    }
}

// MARK: - Constants

private extension TronTransactionHistoryProvider {
    enum Constants {
        /// - Note: Tx history API has 1-based indexing (not 0-based indexing)
        static var initialPageNumber: Int { 1 }
    }
}

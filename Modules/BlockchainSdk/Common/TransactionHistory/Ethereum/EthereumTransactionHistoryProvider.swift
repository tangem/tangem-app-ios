//
//  EthereumTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class EthereumTransactionHistoryProvider<Mapper> where
    Mapper: TransactionHistoryMapper,
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

// MARK: - TransactionHistoryProvider

extension EthereumTransactionHistoryProvider: TransactionHistoryProvider {
    var canFetchHistory: Bool {
        state { state in
            state.page == nil || (state.page?.number ?? 0) < state.totalPages
        }
    }

    var description: String {
        let snapshot = state { $0 }

        return objectDescription(
            self,
            userInfo: [
                "pageNumber": snapshot.page?.number ?? "nil",
                "totalPages": snapshot.totalPages,
                "totalRecordsCount": snapshot.totalRecordsCount,
            ]
        )
    }

    func reset() {
        state { $0 = State() }
        mapper.reset()
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        guard case .address(let address) = request.key else {
            return .anyFail(error: TransactionHistory.ProviderError.requestKeyNotSupported)
        }

        let (resetToken, page) = state { ($0.resetToken, $0.page) }
        let requestPage: Int

        // if indexing is created, load the next page
        if let page {
            requestPage = page.number + 1
        } else {
            requestPage = 0
        }

        let parameters = BlockBookTarget.AddressRequestParameters(
            page: requestPage,
            pageSize: request.limit,
            details: [.txslight],
            filterType: .init(amountType: request.amountType)
        )

        return blockBookProvider.addressData(address: address, parameters: parameters)
            .tryMap { [weak self] response -> TransactionHistory.Response in
                guard let self else {
                    throw BlockchainSdkError.empty
                }

                let records = try mapper.mapToTransactionRecords(
                    response,
                    walletAddress: address,
                    amountType: request.amountType
                )
                .filter { record in
                    self.shouldBeIncludedInHistory(
                        amountType: request.amountType,
                        record: record
                    )
                }

                state { state in
                    guard state.resetToken == resetToken else {
                        return
                    }

                    state.page = TransactionHistoryIndexPage(number: response.page ?? 0)
                    state.totalPages = response.totalPages ?? 0
                    state.totalRecordsCount = response.txs
                }

                return TransactionHistory.Response(records: records)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Auxiliary types

private extension EthereumTransactionHistoryProvider {
    struct State {
        /// Changes with every reset, so a response to a request made before the reset can't update the new state.
        let resetToken = UUID()
        var page: TransactionHistoryIndexPage?
        var totalPages = 0
        var totalRecordsCount = 0
    }
}

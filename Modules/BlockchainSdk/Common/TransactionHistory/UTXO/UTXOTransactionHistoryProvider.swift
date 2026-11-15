//
//  UTXOTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class UTXOTransactionHistoryProvider<Mapper>: MultiNetworkProvider where
    Mapper: TransactionHistoryMapper,
    Mapper.Response == BlockBookAddressResponse,
    Mapper.WalletAddress == [String] {
    var currentProviderIndex: Int = 0
    var providers: [BlockBookUTXOProvider] {
        blockBookProviders
    }

    let blockchainName: String

    private let blockBookProviders: [BlockBookUTXOProvider]
    private let mapper: Mapper
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(
        blockBookProviders: [BlockBookUTXOProvider],
        mapper: Mapper,
        blockchainName: String
    ) {
        self.blockBookProviders = blockBookProviders
        self.mapper = mapper
        self.blockchainName = blockchainName
    }
}

extension UTXOTransactionHistoryProvider: TransactionHistoryProvider {
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
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        let (resetToken, page) = state { ($0.resetToken, $0.page) }
        let requestPage: Int

        // if indexing is created, load the next page
        if let page {
            requestPage = page.number + 1
        } else {
            requestPage = 0
        }

        return providerPublisher { [weak self] provider in
            guard let self else {
                return .anyFail(error: BlockchainSdkError.empty)
            }

            let dataPublisher: AnyPublisher<BlockBookAddressResponse, Error>

            switch request.key {
            case .address(let address):
                let parameters = BlockBookTarget.AddressRequestParameters(
                    page: requestPage,
                    pageSize: request.limit,
                    details: [.txslight]
                )
                dataPublisher = provider.addressData(address: address, parameters: parameters)

            case .xpub(let xpub):
                let parameters = BlockBookTarget.XPUBRequestParameters(
                    page: requestPage,
                    pageSize: request.limit,
                    details: .txslight,
                    tokens: nil
                )
                dataPublisher = provider.addressData(xpub: xpub, parameters: parameters)
            }

            return dataPublisher
                .tryMap { [weak self] response -> TransactionHistory.Response in
                    guard let self else {
                        throw BlockchainSdkError.empty
                    }

                    let records = try mapper.mapToTransactionRecords(
                        response,
                        walletAddress: request.walletAddressType.addresses,
                        amountType: .coin
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
}

// MARK: - Auxiliary types

private extension UTXOTransactionHistoryProvider {
    struct State {
        /// Changes with every reset, so a response to a request made before the reset can't update the new state.
        let resetToken = UUID()
        var page: TransactionHistoryIndexPage?
        var totalPages = 0
        var totalRecordsCount = 0
    }
}

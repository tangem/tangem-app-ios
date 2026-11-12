//
//  AlgorandTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemNetworkUtils

final class AlgorandTransactionHistoryProvider<Mapper> where
    Mapper: TransactionHistoryMapper,
    Mapper.Response == [AlgorandTransactionHistory.Response.Item],
    Mapper.WalletAddress == String {
    /// Configuration connection node for provider
    private let node: NodeInfo

    // MARK: - Properties

    /// Network provider of blockchain
    private let network: TangemProvider<AlgorandIndexProviderTarget>
    private let mapper: Mapper

    private let state = OSAllocatedUnfairLock(initialState: State())

    // MARK: - Init

    init(
        node: NodeInfo,
        networkConfig: TangemProviderConfiguration,
        mapper: Mapper
    ) {
        self.node = node
        network = .init(configuration: networkConfig)
        self.mapper = mapper
    }
}

// MARK: - TransactionHistoryProvider

extension AlgorandTransactionHistoryProvider: TransactionHistoryProvider {
    var canFetchHistory: Bool {
        state { state in
            state.page == nil || (state.page?.next != nil)
        }
    }

    var description: String {
        return objectDescription(
            self,
            userInfo: [
                "nextToken": state { $0.page?.next } ?? "-",
            ]
        )
    }

    func reset() {
        state { $0 = State() }
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        guard case .address(let address) = request.key else {
            return .anyFail(error: TransactionHistory.ProviderError.requestKeyNotSupported)
        }

        let (resetToken, page) = state { ($0.resetToken, $0.page) }

        let target = AlgorandIndexProviderTarget(
            node: node,
            targetType: .getTransactions(address: address, limit: request.limit, next: page?.next)
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        return network.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(AlgorandTransactionHistory.Response.self, using: decoder)
            .withWeakCaptureOf(self)
            .tryMap { provider, response in
                let records = try provider.mapper.mapToTransactionRecords(
                    response.transactions,
                    walletAddress: address,
                    amountType: .coin
                )
                .filter { record in
                    provider.shouldBeIncludedInHistory(
                        amountType: request.amountType,
                        record: record
                    )
                }

                provider.state { state in
                    guard state.resetToken == resetToken else {
                        return
                    }

                    state.page = .init(next: response.nextToken)
                }

                return .init(records: records)
            }
            .mapError { moyaError -> Swift.Error in
                return BlockchainSdkError.failedToParseNetworkResponse()
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Auxiliary types

private extension AlgorandTransactionHistoryProvider {
    struct State {
        /// Changes with every reset, so a response to a request made before the reset can't update the new state.
        let resetToken = UUID()
        var page: TransactionHistoryLinkedPage?
    }
}

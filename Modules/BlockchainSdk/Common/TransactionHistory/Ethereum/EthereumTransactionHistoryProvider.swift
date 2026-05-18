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

    private var page: TransactionHistoryIndexPage?
    private var totalPages: Int = 0
    private var totalRecordsCount: Int = 0

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
        page == nil || (page?.number ?? 0) < totalPages
    }

    var description: String {
        return objectDescription(
            self,
            userInfo: [
                "pageNumber": page?.number ?? "nil",
                "totalPages": totalPages,
                "totalRecordsCount": totalRecordsCount,
            ]
        )
    }

    func reset() {
        page = nil
        totalPages = 0
        totalRecordsCount = 0
        mapper.reset()
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        guard case .address(let address) = request.key else {
            return .anyFail(error: TransactionHistory.ProviderError.requestKeyNotSupported)
        }

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

                page = TransactionHistoryIndexPage(number: response.page ?? 0)
                totalPages = response.totalPages ?? 0
                totalRecordsCount = response.txs

                return TransactionHistory.Response(records: records)
            }
            .eraseToAnyPublisher()
    }
}

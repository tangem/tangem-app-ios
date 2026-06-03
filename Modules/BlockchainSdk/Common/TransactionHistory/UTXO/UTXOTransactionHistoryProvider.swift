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

    private var page: TransactionHistoryIndexPage?
    private var totalPages: Int = 0
    private var totalRecordsCount: Int = 0

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
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        providerPublisher { [weak self] provider in
            guard let self else {
                return .anyFail(error: BlockchainSdkError.empty)
            }

            let requestPage: Int

            // if indexing is created, load the next page
            if let page {
                requestPage = page.number + 1
            } else {
                requestPage = 0
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

                    page = TransactionHistoryIndexPage(number: response.page ?? 0)
                    totalPages = response.totalPages ?? 0
                    totalRecordsCount = response.txs

                    return TransactionHistory.Response(records: records)
                }
                .eraseToAnyPublisher()
        }
    }
}

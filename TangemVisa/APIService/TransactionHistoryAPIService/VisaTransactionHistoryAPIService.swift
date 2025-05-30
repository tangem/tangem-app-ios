//
//  VisaTransactionHistoryAPIService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol VisaTransactionHistoryAPIService {
    func loadHistoryPage(productInstanceId: String, cardId: String, offset: Int, numberOfItemsPerPage: Int) async throws -> VisaTransactionHistoryDTO
}

struct CommonTransactionHistoryService {
    typealias TxHistoryAPIService = APIService<TransactionHistoryAPITarget>
    private let authorizationTokensHandler: VisaAuthorizationTokensHandler
    private let apiService: TxHistoryAPIService

    private let apiType: VisaAPIType

    init(
        apiType: VisaAPIType,
        authorizationTokensHandler: VisaAuthorizationTokensHandler,
        apiService: TxHistoryAPIService
    ) {
        self.apiType = apiType
        self.authorizationTokensHandler = authorizationTokensHandler
        self.apiService = apiService
    }
}

extension CommonTransactionHistoryService: VisaTransactionHistoryAPIService {
    func loadHistoryPage(productInstanceId: String, cardId: String, offset: Int, numberOfItemsPerPage: Int) async throws -> VisaTransactionHistoryDTO {
        return try await apiService.request(
            .init(
                authorizationHeader: authorizationTokensHandler.authorizationHeader,
                target: .txHistoryPage(request: .init(
                    cardId: cardId,
                    productInstanceId: productInstanceId,
                    offset: offset,
                    numberOfItems: numberOfItemsPerPage
                )),
                apiType: apiType
            )
        )
    }
}

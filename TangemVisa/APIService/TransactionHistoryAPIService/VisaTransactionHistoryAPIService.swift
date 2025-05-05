//
//  VisaTransactionHistoryAPIService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol VisaTransactionHistoryAPIService {
    func loadHistoryPage(offset: Int, numberOfItemsPerPage: Int) async throws -> VisaTransactionHistoryDTO
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
    func loadHistoryPage(offset: Int, numberOfItemsPerPage: Int) async throws -> VisaTransactionHistoryDTO {
        guard let accessToken = await authorizationTokensHandler.accessToken else {
            throw VisaAuthorizationTokensHandlerError.missingAccessToken
        }

        let essentialBFFIds = try VisaBFFUtility().getEssentialBFFIds(from: accessToken)
        return try await apiService.request(
            .init(
                authorizationHeader: authorizationTokensHandler.authorizationHeader,
                target: .txHistoryPage(request: .init(
                    customerId: essentialBFFIds.customerId,
                    productInstanceId: essentialBFFIds.productInstanceId,
                    offset: offset,
                    numberOfItems: numberOfItemsPerPage
                )),
                apiType: apiType
            )
        )
    }
}

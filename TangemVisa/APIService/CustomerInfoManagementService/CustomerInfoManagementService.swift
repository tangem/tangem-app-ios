//
//  CustomerInfoManagementService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

protocol CustomerInfoManagementService {
    func loadCustomerInfo(productInstanceId: String) async throws -> CustomerInfoManagementPaymentAccountResponse
}

class CommonCustomerInfoManagementService {
    typealias CIMAPIService = APIService<CustomerInfoManagementAPITarget>
    private let authorizationTokenHandler: VisaAuthorizationTokensHandler
    private let apiService: CIMAPIService

    private let apiType: VisaAPIType

    init(
        apiType: VisaAPIType,
        authorizationTokenHandler: VisaAuthorizationTokensHandler,
        apiService: CIMAPIService
    ) {
        self.apiType = apiType
        self.authorizationTokenHandler = authorizationTokenHandler
        self.apiService = apiService
    }

    private func makeRequest(for target: CustomerInfoManagementAPITarget.Target) async throws -> CustomerInfoManagementAPITarget {
        let authorizationToken = try await authorizationTokenHandler.authorizationHeader

        return .init(
            authorizationToken: authorizationToken,
            target: target,
            apiType: apiType
        )
    }
}

extension CommonCustomerInfoManagementService: CustomerInfoManagementService {
    func loadCustomerInfo(productInstanceId: String) async throws -> CustomerInfoManagementPaymentAccountResponse {
        return try await apiService.request(
            makeRequest(for: .getCustomerInfo(productInstanceId: productInstanceId))
        )
    }
}

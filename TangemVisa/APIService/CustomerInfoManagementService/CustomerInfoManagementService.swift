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
    func loadCustomerInfo(customerId: String) async throws -> CustomerResponse
}

class CommonCustomerInfoManagementService {
    typealias CIMAPIService = APIService<CustomerInfoManagementAPITarget, VisaAPIError>
    private let authorizationTokenHandler: AuthorizationTokenHandler
    private let apiService: CIMAPIService

    init(
        authorizationTokenHandler: AuthorizationTokenHandler,
        apiService: CIMAPIService
    ) {
        self.authorizationTokenHandler = authorizationTokenHandler
        self.apiService = apiService
    }

    private func makeRequest(for target: CustomerInfoManagementAPITarget.Target) async throws -> CustomerInfoManagementAPITarget {
        let authorizationToken = try await authorizationTokenHandler.authorizationHeader

        return .init(
            authorizationToken: authorizationToken,
            target: target
        )
    }
}

extension CommonCustomerInfoManagementService: CustomerInfoManagementService {
    func loadCustomerInfo(customerId: String) async throws -> CustomerResponse {
        return try await apiService.request(
            makeRequest(for: .getCustomerInfo(customerId: customerId))
        )
    }
}

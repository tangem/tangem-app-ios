//
//  VisaCardActivationRemoteStateService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public protocol VisaCardActivationStatusService {
    func getCardActivationStatus(
        authorizationTokens: VisaAuthorizationTokens,
        cardId: String,
        cardPublicKey: String
    ) async throws -> VisaCardActivationStatus
}

struct CommonCardActivationStatusService {
    typealias ActivationStatusService = APIService<ProductActivationAPITarget>
    private let apiService: ActivationStatusService

    private let apiType: VisaAPIType

    init(apiType: VisaAPIType, apiService: ActivationStatusService) {
        self.apiType = apiType
        self.apiService = apiService
    }
}

extension CommonCardActivationStatusService: VisaCardActivationStatusService {
    func getCardActivationStatus(
        authorizationTokens: VisaAuthorizationTokens,
        cardId: String,
        cardPublicKey: String
    ) async throws -> VisaCardActivationStatus {
        let request = ProductActivationAPITarget.ActivationStatusRequest(
            cardId: cardId,
            cardPublicKey: cardPublicKey
        )

        let tokensUtility = AuthorizationTokensUtility()
        let authorizationToken = try tokensUtility.getAuthorizationHeader(from: authorizationTokens)
        return try await apiService.request(.init(
            target: .activationStatus(request: request),
            authorizationToken: authorizationToken,
            apiType: apiType
        ))
    }
}

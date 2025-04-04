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
    typealias ActivationStatusService = APIService<ProductActivationAPITarget, VisaAPIError>
    private let apiService: ActivationStatusService

    init(apiService: ActivationStatusService) {
        self.apiService = apiService
    }
}

extension CommonCardActivationStatusService: VisaCardActivationStatusService {
    func getCardActivationStatus(
        authorizationTokens: VisaAuthorizationTokens,
        cardId: String,
        cardPublicKey: String
    ) async throws -> VisaCardActivationStatus {
        let tokensUtility = AuthorizationTokensUtility()

        guard let accessToken = authorizationTokens.accessToken else {
            throw VisaAuthorizationTokensHandlerError.missingAccessToken
        }

        let ids = try VisaBFFUtility().getEssentialBFFIds(from: accessToken)

        let request = ProductActivationAPITarget.ActivationStatusRequest(
            customerId: ids.customerId,
            productInstanceId: ids.productInstanceId,
            cardId: cardId,
            cardPublicKey: cardPublicKey
        )
        let authorizationToken = try tokensUtility.getAuthorizationHeader(from: authorizationTokens)
        return try await apiService.request(.init(
            target: .activationStatus(request: request),
            authorizationToken: authorizationToken
        ))
    }
}

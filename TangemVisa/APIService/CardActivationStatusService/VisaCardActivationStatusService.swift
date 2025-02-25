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

    func getCardActivationRemoteState(
        authorizationTokens: VisaAuthorizationTokens,
        cardId: String,
        cardPublicKey: String
    ) async throws -> VisaCardActivationRemoteState
}

public extension VisaCardActivationStatusService {
    func getCardActivationRemoteState(
        authorizationTokens: VisaAuthorizationTokens,
        cardId: String,
        cardPublicKey: String
    ) async throws -> VisaCardActivationRemoteState {
        return try await getCardActivationStatus(
            authorizationTokens: authorizationTokens,
            cardId: cardId,
            cardPublicKey: cardPublicKey
        ).activationRemoteState
    }
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

        let ids = try VisaActivationUtility().getEssentialActivationIds(from: accessToken)

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

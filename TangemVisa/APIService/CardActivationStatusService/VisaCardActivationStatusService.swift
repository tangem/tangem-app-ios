//
//  VisaCardActivationRemoteStateService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemPay

public protocol VisaCardActivationStatusService {
    func getCardActivationStatus(
        cardId: String,
        cardPublicKey: String
    ) async throws -> VisaCardActivationStatus
}

struct CommonCardActivationStatusService {
    typealias ActivationStatusService = APIService<ProductActivationAPITarget>
    private let apiService: ActivationStatusService

    private let apiType: TangemPayAPIType

    init(apiType: TangemPayAPIType, apiService: ActivationStatusService) {
        self.apiType = apiType
        self.apiService = apiService
    }
}

extension CommonCardActivationStatusService: VisaCardActivationStatusService {
    func getCardActivationStatus(
        cardId: String,
        cardPublicKey: String
    ) async throws -> VisaCardActivationStatus {
        let request = ProductActivationAPITarget.ActivationStatusRequest(
            cardId: cardId,
            cardPublicKey: cardPublicKey
        )

        return try await apiService.request(.init(
            target: .activationStatus(request: request),
            apiType: apiType
        ))
    }
}

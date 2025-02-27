//
//  CardActivationOrderProvider.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import JWTDecode

public struct VisaCardAcceptanceOrderInfo {
    let activationOrder: VisaCardActivationOrder
    let hashToSignByWallet: Data
}

protocol CardActivationOrderProvider {
    func provideActivationOrderForSign(activationInput: VisaCardActivationInput) async throws -> VisaCardAcceptanceOrderInfo
}

final class CommonCardActivationOrderProvider {
    private let accessTokenProvider: VisaAuthorizationTokensHandler
    private let activationStatusService: VisaCardActivationStatusService
    private let productActivationService: ProductActivationService

    private var loadedOrder: VisaCardAcceptanceOrderInfo?

    init(
        accessTokenProvider: VisaAuthorizationTokensHandler,
        activationStatusService: VisaCardActivationStatusService,
        productActivationService: ProductActivationService
    ) {
        self.accessTokenProvider = accessTokenProvider
        self.activationStatusService = activationStatusService
        self.productActivationService = productActivationService
    }
}

extension CommonCardActivationOrderProvider: CardActivationOrderProvider {
    func provideActivationOrderForSign(activationInput: VisaCardActivationInput) async throws -> VisaCardAcceptanceOrderInfo {
        if let loadedOrder {
            return loadedOrder
        }

        guard let authorizationTokens = await accessTokenProvider.authorizationTokens else {
            VisaLogger.error("Missing access token, can't load activation order data", error: VisaActivationError.missingAccessToken)
            throw VisaActivationError.missingAccessToken
        }

        let activationStatus = try await activationStatusService.getCardActivationStatus(
            authorizationTokens: authorizationTokens,
            cardId: activationInput.cardId,
            cardPublicKey: activationInput.cardPublicKey.hexString
        )

        let hashToSign = try await productActivationService.getVisaCardDeployAcceptance(
            activationOrderId: activationStatus.activationOrder.id,
            customerWalletAddress: activationStatus.activationOrder.customerWalletAddress
        )

        VisaLogger.info("Order loaded and can be processed by card")
        return .init(activationOrder: activationStatus.activationOrder, hashToSignByWallet: Data(hexString: hashToSign))
    }
}

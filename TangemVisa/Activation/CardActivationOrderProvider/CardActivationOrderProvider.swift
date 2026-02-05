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
    func provideActivationOrderForSign(walletAddress: String, activationInput: VisaCardActivationInput) async throws -> VisaCardAcceptanceOrderInfo
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
    func provideActivationOrderForSign(walletAddress: String, activationInput: VisaCardActivationInput) async throws -> VisaCardAcceptanceOrderInfo {
        if let loadedOrder {
            return loadedOrder
        }

        let activationStatus = try await activationStatusService.getCardActivationStatus(
            cardId: activationInput.cardId,
            cardPublicKey: activationInput.cardPublicKey.hexString
        )

        guard let activationOrder = activationStatus.activationOrder else {
            VisaLogger.error("Missing activation order in status response", error: VisaActivationError.missingActivationOrder)
            throw VisaActivationError.missingActivationOrder
        }

        let hashToSign = try await productActivationService.getVisaCardDeployAcceptance(
            activationOrderId: activationOrder.id,
            customerWalletAddress: activationOrder.customerWalletAddress,
            cardWalletAddress: walletAddress
        )

        VisaLogger.info("Order loaded and can be processed by card")
        return .init(activationOrder: activationOrder, hashToSignByWallet: Data(hexString: hashToSign))
    }
}

//
//  MockTangemPayCardTokenizationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import PassKit

final class MockTangemPayCardTokenizationService: TangemPayCardTokenizationService {
    let isAvailable = false

    func passActivationState(cardNumberEnd: String) -> PKSecureElementPass.PassActivationState? {
        nil
    }

    func presentPass(cardNumberEnd: String) {}

    func isWatchPaired() async -> Bool {
        false
    }

    func remotePassActivationState(cardNumberEnd: String) -> PKSecureElementPass.PassActivationState? {
        nil
    }

    func canAddRemotePass(cardNumberEnd: String) -> Bool {
        false
    }

    func initializeTokenization(
        cardId: String,
        cardSecret: String
    ) async throws(TangemPayCardTokenizationError) -> (
        tokenizationReceipt: String,
        requestConfiguration: PKAddPaymentPassRequestConfiguration
    ) {
        throw .missingTokenizationResponse
    }

    func completeTokenization(
        tokenizationReceipt: String,
        certificates: [Data],
        nonce: Data,
        nonceSignature: Data
    ) async throws(TangemPayCardTokenizationError) -> PKAddPaymentPassRequest {
        throw .missingPassRequest
    }
}

//
//  TangemPayCardTokenizationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import PassKit

enum TangemPayCardTokenizationError: Error {
    case sdk(Error)
    case missingTokenizationResponse
    case missingPassRequest
}

protocol TangemPayCardTokenizationService: AnyObject {
    var isAvailable: Bool { get }

    func passActivationState(cardNumberEnd: String) -> PKSecureElementPass.PassActivationState?
    func presentPass(cardNumberEnd: String)

    func isWatchPaired() async -> Bool
    func remotePassActivationState(cardNumberEnd: String) -> PKSecureElementPass.PassActivationState?
    func canAddRemotePass(cardNumberEnd: String) -> Bool

    func initializeTokenization(
        cardId: String,
        cardSecret: String
    ) async throws(TangemPayCardTokenizationError) -> (
        tokenizationReceipt: String,
        requestConfiguration: PKAddPaymentPassRequestConfiguration
    )

    func completeTokenization(
        tokenizationReceipt: String,
        certificates: [Data],
        nonce: Data,
        nonceSignature: Data
    ) async throws(TangemPayCardTokenizationError) -> PKAddPaymentPassRequest
}

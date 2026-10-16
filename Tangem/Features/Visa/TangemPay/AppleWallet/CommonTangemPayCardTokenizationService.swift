//
//  CommonTangemPayCardTokenizationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import PassKit
import TangemVisa

#if canImport(MeaPushProvisioning)
import MeaPushProvisioning

final class CommonTangemPayCardTokenizationService: TangemPayCardTokenizationService {
    var isAvailable: Bool {
        let canMakePayments = PKPaymentAuthorizationViewController.canMakePayments()
        let canAddPaymentPass = PKAddPaymentPassViewController.canAddPaymentPass()

        if !canMakePayments || !canAddPaymentPass {
            VisaLogger.info("Apple Wallet unavailable, canMakePayments: \(canMakePayments), canAddPaymentPass: \(canAddPaymentPass)")
        }

        return canMakePayments && canAddPaymentPass
    }

    func passActivationState(cardNumberEnd: String) -> PKSecureElementPass.PassActivationState? {
        guard MeaPushProvisioning.secureElementPassExists(withPrimaryAccountNumberSuffix: cardNumberEnd) else {
            return nil
        }

        return MeaPushProvisioning.secureElementPass(withPrimaryAccountNumberSuffix: cardNumberEnd).passActivationState
    }

    func presentPass(cardNumberEnd: String) {
        MeaPushProvisioning.presentSecureElementPass(withPrimaryAccountNumberSuffix: cardNumberEnd)
    }

    func isWatchPaired() async -> Bool {
        await withCheckedContinuation { continuation in
            MeaPushProvisioning.isWatchPaired { isPaired in
                continuation.resume(returning: isPaired)
            }
        }
    }

    func remotePassActivationState(cardNumberEnd: String) -> PKSecureElementPass.PassActivationState? {
        guard MeaPushProvisioning.remoteSecureElementPassExists(withPrimaryAccountNumberSuffix: cardNumberEnd) else {
            return nil
        }

        return MeaPushProvisioning.remoteSecureElementPass(withPrimaryAccountNumberSuffix: cardNumberEnd).passActivationState
    }

    func canAddRemotePass(cardNumberEnd: String) -> Bool {
        MeaPushProvisioning.canAddRemoteSecureElementPass(withPrimaryAccountNumberSuffix: cardNumberEnd)
    }

    func initializeTokenization(
        cardId: String,
        cardSecret: String
    ) async throws(TangemPayCardTokenizationError) -> (
        tokenizationReceipt: String,
        requestConfiguration: PKAddPaymentPassRequestConfiguration
    ) {
        let parameters = MppCardDataParameters(cardId: cardId, cardSecret: cardSecret)

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<InitializeResult, Never>) in
            MeaPushProvisioning.initializeOemTokenization(parameters) { data, error in
                if let error {
                    continuation.resume(returning: .failure(.sdk(error)))
                    return
                }

                guard let data, let requestConfiguration = data.addPaymentPassRequestConfiguration else {
                    continuation.resume(returning: .failure(.missingTokenizationResponse))
                    return
                }

                continuation.resume(returning: .success((data.tokenizationReceipt, requestConfiguration)))
            }
        }

        return try result.get()
    }

    func completeTokenization(
        tokenizationReceipt: String,
        certificates: [Data],
        nonce: Data,
        nonceSignature: Data
    ) async throws(TangemPayCardTokenizationError) -> PKAddPaymentPassRequest {
        let tokenizationData = MppCompleteOemTokenizationData(
            tokenizationReceipt: tokenizationReceipt,
            certificates: certificates,
            nonce: nonce,
            nonceSignature: nonceSignature
        )

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<CompleteResult, Never>) in
            MeaPushProvisioning.completeOemTokenization(tokenizationData) { data, error in
                if let error {
                    continuation.resume(returning: .failure(.sdk(error)))
                    return
                }

                guard let request = data?.addPaymentPassRequest else {
                    continuation.resume(returning: .failure(.missingPassRequest))
                    return
                }

                continuation.resume(returning: .success(request))
            }
        }

        return try result.get()
    }
}

private extension CommonTangemPayCardTokenizationService {
    typealias InitializeResult = Result<
        (tokenizationReceipt: String, requestConfiguration: PKAddPaymentPassRequestConfiguration),
        TangemPayCardTokenizationError
    >
    typealias CompleteResult = Result<PKAddPaymentPassRequest, TangemPayCardTokenizationError>
}
#else
final class CommonTangemPayCardTokenizationService: TangemPayCardTokenizationService {
    var isAvailable: Bool { false }

    func passActivationState(cardNumberEnd: String) -> PKSecureElementPass.PassActivationState? { nil }

    func presentPass(cardNumberEnd: String) {}

    func isWatchPaired() async -> Bool { false }

    func remotePassActivationState(cardNumberEnd: String) -> PKSecureElementPass.PassActivationState? { nil }

    func canAddRemotePass(cardNumberEnd: String) -> Bool { false }

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
#endif

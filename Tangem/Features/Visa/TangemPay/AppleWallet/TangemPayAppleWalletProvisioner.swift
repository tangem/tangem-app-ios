//
//  TangemPayAppleWalletProvisioner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import PassKit
import TangemPay

enum TangemPayAppleWalletProvisioningError: Error {
    case missingCardSecret
    case unknownError
    case api(TangemPayAPIServiceError)
    case tokenization(TangemPayCardTokenizationError)
    case passKit(Error)
    case presentationUnavailable
}

final class TangemPayAppleWalletProvisioner {
    private let tokenizationService: TangemPayCardTokenizationService

    init(tokenizationService: TangemPayCardTokenizationService) {
        self.tokenizationService = tokenizationService
    }

    @MainActor
    func isEligible(_ card: TangemPayCard, customerState: VisaCustomerInfoResponse.CustomerState) async -> Bool {
        guard tokenizationService.isAvailable,
              customerState == .active,
              card.productInstance.status == .active,
              !card.isAwaitingActivation else {
            return false
        }

        return await passActivationStates(for: card).contains { $0?.requiresUserAction ?? true }
    }

    @MainActor
    func isMissingPass(card: TangemPayCard) async -> Bool {
        await passActivationStates(for: card).contains { $0 == nil }
    }

    @MainActor
    func presentPassIfActivationRequired(card: TangemPayCard) -> Bool {
        guard tokenizationService.passActivationState(cardNumberEnd: card.cardNumberEnd)?.requiresUserAction == true else {
            return false
        }

        tokenizationService.presentPass(cardNumberEnd: card.cardNumberEnd)
        return true
    }

    @MainActor
    func addToWallet(card: TangemPayCard) async throws(TangemPayAppleWalletProvisioningError) -> PKSecureElementPass.PassActivationState {
        let details: TangemPayCardProcessorDetailsResponse
        do {
            details = try await card.customerService.getCardProcessorDetails(cardId: card.cardId)
        } catch {
            throw .api(error)
        }

        guard let cardSecret = details.cardSecret?.trimmingCharacters(in: .whitespacesAndNewlines), !cardSecret.isEmpty else {
            throw .missingCardSecret
        }

        let tokenizationReceipt: String
        let requestConfiguration: PKAddPaymentPassRequestConfiguration
        do {
            (tokenizationReceipt, requestConfiguration) = try await tokenizationService.initializeTokenization(
                cardId: details.cardId,
                cardSecret: cardSecret
            )
        } catch {
            throw .tokenization(error)
        }

        let presenter = TangemPayAddPaymentPassPresenter(tokenizationService: tokenizationService, tokenizationReceipt: tokenizationReceipt)

        return try await presenter.present(requestConfiguration: requestConfiguration)
    }
}

private extension TangemPayAppleWalletProvisioner {
    @MainActor
    func passActivationStates(for card: TangemPayCard) async -> [PKSecureElementPass.PassActivationState?] {
        let phoneState = tokenizationService.passActivationState(cardNumberEnd: card.cardNumberEnd)

        guard await tokenizationService.isWatchPaired() else {
            return [phoneState]
        }

        if let watchState = tokenizationService.remotePassActivationState(cardNumberEnd: card.cardNumberEnd) {
            return [phoneState, watchState]
        }

        return tokenizationService.canAddRemotePass(cardNumberEnd: card.cardNumberEnd) ? [phoneState, nil] : [phoneState]
    }
}

extension PKSecureElementPass.PassActivationState {
    var requiresUserAction: Bool {
        switch self {
        case .requiresActivation, .activating:
            true
        case .activated, .suspended, .deactivated:
            false
        @unknown default:
            false
        }
    }
}

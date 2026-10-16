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
import TangemVisa

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
    func isEligible(_ card: TangemPayCard, cardIndex: Int, customerState: VisaCustomerInfoResponse.CustomerState) async -> Bool {
        let isAvailable = tokenizationService.isAvailable

        guard isAvailable,
              customerState == .active,
              card.productInstance.status == .active,
              !card.isAwaitingActivation else {
            VisaLogger.info(
                "Apple Wallet button hidden for card #\(cardIndex): tokenization available: \(isAvailable), "
                    + "customer state: \(customerState), card status: \(card.productInstance.status), "
                    + "awaiting activation: \(card.isAwaitingActivation)"
            )
            return false
        }

        let passStates = await passActivationStates(for: card)
        let isEligible = passStates.contains { $0?.requiresUserAction ?? true }
        let passStatesDescription = passStates.map { $0?.logDescription ?? "missing" }.joined(separator: ", ")
        VisaLogger.info("Apple Wallet button \(isEligible ? "shown" : "hidden") for card #\(cardIndex), passes: [\(passStatesDescription)]")

        return isEligible
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

private extension PKSecureElementPass.PassActivationState {
    var logDescription: String {
        switch self {
        case .activated: "activated"
        case .requiresActivation: "requiresActivation"
        case .activating: "activating"
        case .suspended: "suspended"
        case .deactivated: "deactivated"
        @unknown default: "unknown(\(rawValue))"
        }
    }
}

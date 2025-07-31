//
//  VisaCardActivationInput.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct VisaCardActivationInput: Equatable, Codable {
    public let cardId: String
    public let cardPublicKey: Data
    public let isAccessCodeSet: Bool
    public let walletAddress: String?

    public init(cardId: String, cardPublicKey: Data, isAccessCodeSet: Bool, walletAddress: String? = nil) {
        self.cardId = cardId
        self.cardPublicKey = cardPublicKey
        self.isAccessCodeSet = isAccessCodeSet
        self.walletAddress = walletAddress
    }

    init(cardInput: VisaCardActivationInput, cardActivationResponse: CardActivationResponse, isTestnet: Bool) throws {
        cardId = cardInput.cardId
        cardPublicKey = cardInput.cardPublicKey
        isAccessCodeSet = true
        walletAddress = try VisaUtilities.makeAddress(using: cardActivationResponse, isTestnet: isTestnet).value
    }
}

public enum VisaCardActivationLocalState: Codable {
    case activated(authTokens: VisaAuthorizationTokens)
    case activationStarted(activationInput: VisaCardActivationInput, authTokens: VisaAuthorizationTokens, activationStatus: VisaCardActivationStatus)
    case notStartedActivation(activationInput: VisaCardActivationInput)
    case blocked

    public var authTokens: VisaAuthorizationTokens? {
        switch self {
        case .activated(let authTokens):
            return authTokens
        case .activationStarted(_, let authTokens, _):
            return authTokens
        case .notStartedActivation, .blocked:
            return nil
        }
    }

    public var activationInput: VisaCardActivationInput? {
        switch self {
        case .activated, .blocked:
            return nil
        case .activationStarted(let activationInput, _, _):
            return activationInput
        case .notStartedActivation(let activationInput):
            return activationInput
        }
    }

    public var isActivated: Bool {
        activationInput == nil
    }
}

public struct VisaCardActivationStatus: Codable {
    public let activationRemoteState: VisaCardActivationRemoteState
    public let activationOrder: VisaCardActivationOrder?

    private enum CodingKeys: String, CodingKey {
        case activationRemoteState = "status"
        case activationOrder = "order"
    }
}

public enum VisaCardActivationRemoteState: String, Codable, Equatable {
    /// 1 step. It means that backend didn't receive
    /// acceptance from Visa card for payment account deployment.
    case cardWalletSignatureRequired = "card_wallet_signature_required"
    /// 2 step. Backend already have
    /// acceptance from Visa card and now awaits to customer wallet
    /// to sign acceptance message. This will validate that user have both wallets
    case customerWalletSignatureRequired = "customer_wallet_signature_required"
    /// 3 step. Payment account deployment is in process no need to do anything in activation process
    case paymentAccountDeploying = "payment_account_deploying"
    /// 4 step. Payment account already deployed now user must select PIN code that will be used during
    /// payments using card in fiat terminals
    case waitingPinCode = "pin_code_required"
    /// 5 step. Issuer accepted PIN code and processing request. This is the last step of activation process
    case waitingForActivationFinishing = "waiting_for_activation"
    case activated
    /// This can happen due to some regulation issues or might be because of card loss. Anyway user need to contact support
    case blockedForActivation = "blocked_for_activation"
    /// Something went wrong on BFF or backend side. User need to contact support
    case failed
}

public struct VisaCardActivationOrder: Codable {
    public let id: String
    public let customerId: String
    public let customerWalletAddress: String
    public let cardWalletAddress: String
    public let updatedAt: Date?
    public let stepChangeCode: Int?
}

/// Step change code specifiend on backend, will be extended later
enum CardActivationOrderStepChangeCode: Int {
    /// External service returned error during PIN validation. Need to request new PIN from user
    case pinValidation = 1000
}

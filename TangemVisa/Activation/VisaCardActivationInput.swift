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

    init(cardInput: VisaCardActivationInput, cardActivationResponse: CardActivationResponse, isTestnet: Bool = false) throws {
        cardId = cardInput.cardId
        cardPublicKey = cardInput.cardPublicKey
        isAccessCodeSet = true

        let visaUtilities = VisaUtilities(isTestnet: isTestnet)
        walletAddress = try visaUtilities.makeAddress(using: cardActivationResponse).value
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
    public let activationOrder: VisaCardActivationOrder

    private enum CodingKeys: String, CodingKey {
        case activationRemoteState = "activationStatus"
        case activationOrder
    }
}

public enum VisaCardActivationRemoteState: String, Codable, Equatable {
    /// 1 step. It means that backend didn't receive
    /// acceptance from Visa card for payment account deployment.
    case cardWalletSignatureRequired
    /// 2 step. Backend already have
    /// acceptance from Visa card and now awaits to customer wallet
    /// to sign acceptance message. This will validate that user have both wallets
    case customerWalletSignatureRequired
    /// 3 step. Payment account deployment is in process no need to do anything in activation process
    case paymentAccountDeploying
    /// 4 step. Payment account already deployed now user must select PIN code that will be used during
    /// payments using card in fiat terminals
    case waitingPinCode
    /// 5 step. Issuer accepted PIN code and processing request. This is the last step of activation process
    case waitingForActivationFinishing
    case activated
    /// This can happen due to some regulation issues or might be because of card loss. Anyway user need to contact support
    case blockedForActivation
}

public struct VisaCardActivationOrder: Codable {
    public let id: String
    public let customerId: String
    public let customerWalletAddress: String
    public let updatedAt: Date?
    public let stepChangeCode: Int?
}

/// Step change code specifiend on backend, will be extended later
enum CardActivationOrderStepChangeCode: Int {
    /// External service returned error during PIN validation. Need to request new PIN from user
    case pinValidation = 1000
}

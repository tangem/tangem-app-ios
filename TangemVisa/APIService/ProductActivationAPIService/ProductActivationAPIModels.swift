//
//  ProductActivationAPIModels.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Activation status

extension ProductActivationAPITarget {
    struct ActivationStatusRequest: Encodable {
        let cardId: String
        let cardPublicKey: String
    }
}

extension ProductActivationAPITarget {
    struct ProductActivationEmptyResponse: Decodable {}
}

// MARK: - Visa card deploy acceptance requests - 2 tap related

extension ProductActivationAPITarget {
    /// Requests
    enum AcceptanceMessageType: String, Encodable {
        case cardWallet = "card_wallet"
        case customerWallet = "customer_wallet"
    }

    struct GetAcceptanceMessageRequest: Encodable {
        let type: AcceptanceMessageType
        let customerWalletAddress: String
        let cardWalletAddress: String
    }

    struct VisaCardDeployAcceptanceRequest: Encodable {
        let orderId: String
        let cardWallet: DeployAcceptanceData
        let otp: OTPData
        let deployAcceptanceSignature: String
    }

    /// Responses
    struct GetAcceptanceMessageResponse: Decodable {
        let hash: String
    }
}

extension ProductActivationAPITarget.VisaCardDeployAcceptanceRequest {
    /// Related data
    struct DeployAcceptanceData: Encodable {
        let address: String
        let cardWalletConfirmation: SignatureData?
    }

    struct OTPData: Encodable {
        let rootOtp: String
        let counter: Int
    }

    struct SignatureData: Encodable {
        let challenge: String
        let walletSignature: String
        let cardSalt: String
        let cardSignature: String
    }
}

// MARK: - Customer wallet deploy acceptance requests - 3 tap related

extension ProductActivationAPITarget {
    struct CustomerWalletDeployAcceptanceRequest: Encodable {
        let orderId: String
        let customerWallet: AcceptanceData
    }
}

extension ProductActivationAPITarget.CustomerWalletDeployAcceptanceRequest {
    struct AcceptanceData: Encodable {
        let deployAcceptanceSignature: String
        let address: String
    }
}

// MARK: - PIN code related

extension ProductActivationAPITarget {
    struct SetupPINRequest: Encodable {
        let orderId: String
        let sessionId: String
        let iv: String
        let pin: String
    }
}

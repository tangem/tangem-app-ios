//
//  ProductActivationAPIService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

protocol ProductActivationService {
    func getVisaCardDeployAcceptance(
        activationOrderId: String,
        customerWalletAddress: String,
        cardWalletAddress: String
    ) async throws -> String
    func sendSignedVisaCardDeployAcceptance(
        activationOrderId: String,
        cardWalletAddress: String,
        signedAcceptance: String,
        rootOtp: String,
        rootOtpCounter: Int
    ) async throws

    func getCustomerWalletDeployAcceptance(
        activationOrderId: String,
        customerWalletAddress: String,
        cardWalletAddress: String
    ) async throws -> String
    func sendSignedCustomerWalletDeployAcceptance(
        activationOrderId: String,
        customerWalletAddress: String,
        deployAcceptanceSignature: String
    ) async throws

    func sendSelectedPINCodeToIssuer(
        activationOrderId: String,
        sessionKey: String,
        iv: String,
        encryptedPin: String
    ) async throws
}

struct CommonProductActivationService {
    typealias ActivationAPIService = APIService<ProductActivationAPITarget>
    private let apiService: ActivationAPIService

    private let apiType: TangemPayAPIType

    init(
        apiType: TangemPayAPIType,
        apiService: ActivationAPIService
    ) {
        self.apiType = apiType
        self.apiService = apiService
    }

    private func sendRequest<T: Decodable>(target: ProductActivationAPITarget.Target) async throws -> T {
        return try await apiService.request(.init(
            target: target,
            apiType: apiType
        ))
    }
}

extension CommonProductActivationService: ProductActivationService {
    func getVisaCardDeployAcceptance(
        activationOrderId: String,
        customerWalletAddress: String,
        cardWalletAddress: String
    ) async throws -> String {
        let response: ProductActivationAPITarget.GetAcceptanceMessageResponse = try await sendRequest(
            target: .getAcceptanceMessage(request: .init(
                type: .cardWallet,
                customerWalletAddress: customerWalletAddress,
                cardWalletAddress: cardWalletAddress
            ))
        )
        return response.hash
    }

    func sendSignedVisaCardDeployAcceptance(
        activationOrderId: String,
        cardWalletAddress: String,
        signedAcceptance: String,
        rootOtp: String,
        rootOtpCounter: Int
    ) async throws {
        let defaultEmptyValue = ""
        let data: ProductActivationAPITarget.VisaCardDeployAcceptanceRequest.DeployAcceptanceData = .init(
            address: cardWalletAddress,
            cardWalletConfirmation: .init(
                challenge: defaultEmptyValue,
                walletSignature: defaultEmptyValue,
                cardSalt: defaultEmptyValue,
                cardSignature: defaultEmptyValue
            )
        )
        let _: ProductActivationAPITarget.ProductActivationEmptyResponse = try await sendRequest(
            target: .approveDeployByVisaCard(request: .init(
                orderId: activationOrderId,
                cardWallet: data,
                otp: .init(rootOtp: rootOtp, counter: rootOtpCounter),
                deployAcceptanceSignature: signedAcceptance
            ))
        )
    }

    func getCustomerWalletDeployAcceptance(
        activationOrderId: String,
        customerWalletAddress: String,
        cardWalletAddress: String
    ) async throws -> String {
        let response: ProductActivationAPITarget.GetAcceptanceMessageResponse = try await sendRequest(
            target: .getAcceptanceMessage(request: .init(
                type: .customerWallet,
                customerWalletAddress: customerWalletAddress,
                cardWalletAddress: cardWalletAddress
            ))
        )
        return response.hash
    }

    func sendSignedCustomerWalletDeployAcceptance(
        activationOrderId: String,
        customerWalletAddress: String,
        deployAcceptanceSignature: String
    ) async throws {
        let _: ProductActivationAPITarget.ProductActivationEmptyResponse = try await sendRequest(
            target: .approveDeployByCustomerWallet(request: .init(
                orderId: activationOrderId,
                customerWallet: .init(deployAcceptanceSignature: deployAcceptanceSignature, address: customerWalletAddress)
            ))
        )
    }

    func sendSelectedPINCodeToIssuer(
        activationOrderId: String,
        sessionKey: String,
        iv: String,
        encryptedPin: String
    ) async throws {
        let _: ProductActivationAPITarget.ProductActivationEmptyResponse = try await sendRequest(
            target: .setupPIN(request: .init(
                orderId: activationOrderId,
                sessionId: sessionKey,
                iv: iv,
                pin: encryptedPin
            ))
        )
    }
}

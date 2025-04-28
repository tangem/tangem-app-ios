//
//  ProductActivationAPIService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

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
    private let authorizationTokensHandler: VisaAuthorizationTokensHandler
    private let apiService: ActivationAPIService

    private let apiType: VisaAPIType

    init(
        apiType: VisaAPIType,
        authorizationTokensHandler: VisaAuthorizationTokensHandler,
        apiService: ActivationAPIService
    ) {
        self.apiType = apiType
        self.authorizationTokensHandler = authorizationTokensHandler
        self.apiService = apiService
    }

    private func sendRequest<T: Decodable>(target: ProductActivationAPITarget.Target) async throws -> T {
        let authorizationToken = try await authorizationTokensHandler.authorizationHeader

        return try await apiService.request(.init(
            target: target,
            authorizationToken: authorizationToken,
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
        return response.data.hash
    }

    func sendSignedVisaCardDeployAcceptance(
        activationOrderId: String,
        cardWalletAddress: String,
        signedAcceptance: String,
        rootOtp: String,
        rootOtpCounter: Int
    ) async throws {
        let defaultEmptyValue = "N/A"
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
        return response.data.hash
    }

    func sendSignedCustomerWalletDeployAcceptance(
        activationOrderId: String,
        customerWalletAddress: String,
        deployAcceptanceSignature: String
    ) async throws {
        let _: ProductActivationAPITarget.ProductActivationEmptyResponse = try await sendRequest(
            target: .approveDeployByCustomerWallet(request: .init(
                orderId: activationOrderId,
                customerWallet: .init(deployAcceptanceSignature: deployAcceptanceSignature)
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

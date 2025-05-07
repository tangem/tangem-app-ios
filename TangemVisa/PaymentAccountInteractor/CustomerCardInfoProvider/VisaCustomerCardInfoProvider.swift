//
//  VisaCustomerCardInfoProvider.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public protocol VisaCustomerCardInfoProvider {
    func loadPaymentAccount(cardId: String, cardWalletAddress: String) async throws -> VisaCustomerCardInfo
}

struct CommonCustomerCardInfoProvider {
    private let isTestnet: Bool
    private let authorizationTokensHandler: VisaAuthorizationTokensHandler?
    private let customerInfoManagementService: CustomerInfoManagementService?
    private let evmSmartContractInteractor: EVMSmartContractInteractor

    init(
        isTestnet: Bool,
        authorizationTokensHandler: VisaAuthorizationTokensHandler?,
        customerInfoManagementService: CustomerInfoManagementService?,
        evmSmartContractInteractor: EVMSmartContractInteractor
    ) {
        self.isTestnet = isTestnet
        self.authorizationTokensHandler = authorizationTokensHandler
        self.customerInfoManagementService = customerInfoManagementService
        self.evmSmartContractInteractor = evmSmartContractInteractor
    }
}

extension CommonCustomerCardInfoProvider: VisaCustomerCardInfoProvider {
    func loadPaymentAccount(cardId: String, cardWalletAddress: String) async throws -> VisaCustomerCardInfo {
        do {
            return try await loadPaymentAccountFromCIM(cardId: cardId, cardWalletAddress: cardWalletAddress)
        } catch let error as VisaPaymentAccountAddressProviderError {
            VisaLogger.error("Missing information for selected card", error: error)
            if error != .bffIsNotAvailable {
                throw error
            }
        } catch {
            VisaLogger.error("Failed to load payment account info from CIM. Continuing with registry", error: error)
        }

        let paymentAccount = try await loadPaymentAccountFromRegistry(cardWalletAddress: cardWalletAddress)
        return VisaCustomerCardInfo(
            paymentAccount: paymentAccount,
            cardId: cardId,
            cardWalletAddress: cardWalletAddress,
            customerInfo: nil
        )
    }

    private func getProductInstanceId() async throws -> String {
        guard let authorizationTokensHandler else {
            throw VisaPaymentAccountAddressProviderError.bffIsNotAvailable
        }

        if await !authorizationTokensHandler.containsAccessToken {
            try await authorizationTokensHandler.forceRefreshToken()
        }

        guard let accessToken = await authorizationTokensHandler.accessToken else {
            throw VisaAuthorizationTokensHandlerError.missingAccessToken
        }

        guard let productInstanceId = JWTTokenHelper().getProductInstanceID(from: accessToken) else {
            throw VisaAuthorizationTokensHandlerError.missingMandatoryInfoInAccessToken
        }

        return productInstanceId
    }

    private func loadPaymentAccountFromCIM(cardId: String, cardWalletAddress: String) async throws -> VisaCustomerCardInfo {
        guard let customerInfoManagementService else {
            throw VisaPaymentAccountAddressProviderError.bffIsNotAvailable
        }

        let productInstanceId = try await getProductInstanceId()
        let paymentAccountInfo = try await customerInfoManagementService.loadCustomerInfo(productInstanceId: productInstanceId)

        return VisaCustomerCardInfo(
            paymentAccount: paymentAccountInfo.address,
            cardId: cardId,
            cardWalletAddress: cardWalletAddress,
            customerInfo: nil
        )
    }

    private func loadPaymentAccountFromRegistry(cardWalletAddress: String) async throws -> String {
        VisaLogger.info("Start searching PaymentAccount for card")
        let registryAddress = try VisaConfigProvider.shared().getRegistryAddress(isTestnet: isTestnet)
        VisaLogger.info("Requesting PaymentAccount from bridge")

        let request = VisaSmartContractRequest(
            contractAddress: registryAddress,
            method: GetPaymentAccountByCardMethod(cardWalletAddress: cardWalletAddress)
        )

        do {
            let response = try await evmSmartContractInteractor.ethCall(request: request).async()
            let paymentAccount = try AddressParser(isTestnet: isTestnet).parseAddressResponse(response)
            VisaLogger.info("PaymentAccount founded")
            return paymentAccount
        } catch {
            VisaLogger.error("Failed to receive PaymentAccount", error: error)
            throw error
        }
    }
}

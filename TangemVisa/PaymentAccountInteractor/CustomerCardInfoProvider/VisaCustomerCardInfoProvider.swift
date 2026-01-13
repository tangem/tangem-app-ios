//
//  VisaCustomerCardInfoProvider.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemPay

public protocol VisaCustomerCardInfoProvider {
    func loadPaymentAccount(cardWalletAddress: String) async throws -> VisaCustomerCardInfo
}

/// For backwards compatibility.
/// Will be removed in next [REDACTED_INFO]
public extension VisaCustomerCardInfoProvider {
    func loadPaymentAccount(cardId: String, cardWalletAddress: String) async throws -> VisaCustomerCardInfo {
        try await loadPaymentAccount(cardWalletAddress: cardWalletAddress)
    }
}

struct CommonCustomerCardInfoProvider {
    private let isTestnet: Bool
    private let customerInfoManagementService: TangemPayCustomerService?
    private let evmSmartContractInteractor: EVMSmartContractInteractor

    init(
        isTestnet: Bool,
        customerInfoManagementService: TangemPayCustomerService?,
        evmSmartContractInteractor: EVMSmartContractInteractor
    ) {
        self.isTestnet = isTestnet
        self.customerInfoManagementService = customerInfoManagementService
        self.evmSmartContractInteractor = evmSmartContractInteractor
    }
}

extension CommonCustomerCardInfoProvider: VisaCustomerCardInfoProvider {
    func loadPaymentAccount(cardWalletAddress: String) async throws -> VisaCustomerCardInfo {
        do {
            return try await loadPaymentAccountFromCIM(cardWalletAddress: cardWalletAddress)
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
            cardWalletAddress: cardWalletAddress,
            customerInfo: nil
        )
    }

    private func loadPaymentAccountFromCIM(cardWalletAddress: String) async throws -> VisaCustomerCardInfo {
        guard let customerInfoManagementService else {
            throw VisaPaymentAccountAddressProviderError.bffIsNotAvailable
        }

        let customerInfo = try await customerInfoManagementService.loadCustomerInfo()

        guard let paymentAccount = customerInfo.paymentAccount else {
            throw VisaPaymentAccountAddressProviderError.missingPaymentAccountForCard
        }

        return VisaCustomerCardInfo(
            paymentAccount: paymentAccount.address,
            cardWalletAddress: cardWalletAddress,
            customerInfo: customerInfo
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

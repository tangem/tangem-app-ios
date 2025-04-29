//
//  CommonPaymentAccountInteractor.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Handles interaction with a Visa payment account on the blockchain.
/// This includes loading balances and card settings via smart contract calls.
struct CommonPaymentAccountInteractor {
    let visaToken: Token

    private let customerCardInfo: VisaCustomerCardInfo
    private let isTestnet: Bool

    private let evmSmartContractInteractor: EVMSmartContractInteractor

    init(
        customerCardInfo: VisaCustomerCardInfo,
        visaToken: Token,
        isTestnet: Bool,
        evmSmartContractInteractor: EVMSmartContractInteractor
    ) {
        self.customerCardInfo = customerCardInfo
        self.visaToken = visaToken
        self.isTestnet = isTestnet
        self.evmSmartContractInteractor = evmSmartContractInteractor
    }
}

extension CommonPaymentAccountInteractor: VisaPaymentAccountInteractor {
    /// The blockchain address of the payment account.
    var accountAddress: String { customerCardInfo.paymentAccount }

    /// The address of the card wallet.
    var cardWalletAddress: String { customerCardInfo.cardWalletAddress }

    /// Loads all types of balances (total, verified, available, blocked, debt) from the payment account.
    /// All balances requested as separated calls to payment account functions
    /// - Returns: A `VisaBalances` instance containing all the retrieved balances.
    /// - Throws: An error if balance retrieval fails.
    func loadBalances() async throws -> VisaBalances {
        VisaLogger.info("Attempting to load all balances from balances")
        let loadedBalances: VisaBalances
        do {
            async let totalBalance = try await evmSmartContractInteractor.ethCall(
                request: VisaSmartContractRequest(
                    contractAddress: visaToken.contractAddress,
                    method: GetTotalBalanceMethod(paymentAccountAddress: accountAddress)
                )
            ).async()

            async let verifiedBalance = try requestAmount(type: .verifiedBalance)
            async let availableAmount = try requestAmount(type: .availableForPayment)
            async let blockedAmount = try requestAmount(type: .blocked)
            async let debtAmount = try requestAmount(type: .debt)

            loadedBalances = try await VisaBalances(
                totalBalance: convertToDecimal(totalBalance),
                verifiedBalance: convertToDecimal(verifiedBalance),
                available: convertToDecimal(availableAmount),
                blocked: convertToDecimal(blockedAmount),
                debt: convertToDecimal(debtAmount)
            )

            VisaLogger.info("All balances sucessfully loaded")
            return loadedBalances
        } catch {
            VisaLogger.error("Failed to load balances", error: error)
            throw error
        }
    }

    /// Loads the card settings stored inside payment account for linked card.
    /// Card settings returned from payment account as an object
    /// Validates wallet association before attempting to load settings.
    /// - Returns: A `VisaPaymentAccountCardSettings` instance with current card configuration.
    /// - Throws: An error if wallet is not associated or retrieval fails.
    func loadCardSettings() async throws -> VisaPaymentAccountCardSettings {
        VisaLogger.info("Attempting to load card settings from payment account")
        do {
            try await checkWalletAddressAssociation()

            let cardSettings = try await loadCardSettingsFromBlockchain()
            VisaLogger.info("Card settings sucessfully loaded")
            return cardSettings
        } catch {
            VisaLogger.error("Failed to load card settings", error: error)
            throw error
        }
    }

    /// Validates that selected Visa card is linked to payment account
    /// - Throws: An error if card wallet address is not registered in payment account
    private func checkWalletAddressAssociation() async throws {
        let method = GetCardsListMethod()
        let paymentAccountAddressesResponse = try await evmSmartContractInteractor.ethCall(
            request: VisaSmartContractRequest(contractAddress: accountAddress, method: method)
        ).async()
        let addressesList = try AddressParser(isTestnet: isTestnet).parseAddressesResponse(paymentAccountAddressesResponse)

        guard addressesList.contains(cardWalletAddress) else {
            throw VisaPaymentAccountError.cardNotRegisteredToAccount
        }
    }

    private func loadCardSettingsFromBlockchain() async throws -> VisaPaymentAccountCardSettings {
        let method = GetCardInfoMethod(cardAddress: cardWalletAddress)
        let response = try await evmSmartContractInteractor.ethCall(
            request: VisaSmartContractRequest(contractAddress: accountAddress, method: method)
        ).async()

        let parser = PaymentAccountCardSettingsParser(decimalCount: visaToken.decimalCount)
        let settings = try parser.parse(response: response)
        return settings
    }
}

private extension CommonPaymentAccountInteractor {
    func requestAmount(type: GetAmountMethod.AmountType) async throws -> String {
        do {
            return try await evmSmartContractInteractor.ethCall(request: amountRequest(for: type)).async()
        } catch {
            VisaLogger.error("Failed to load amount of type: \(type.rawValue)", error: error)
            throw error
        }
    }

    func amountRequest(for amountType: GetAmountMethod.AmountType) -> VisaSmartContractRequest {
        let method = GetAmountMethod(amountType: amountType)
        return VisaSmartContractRequest(contractAddress: accountAddress, method: method)
    }

    func convertToDecimal(_ value: String) -> Decimal? {
        let decimal = EthereumUtils.parseEthereumDecimal(value, decimalsCount: visaToken.decimalCount)
        return decimal
    }
}

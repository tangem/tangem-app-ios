//
//  VisaBridgeInteractorBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct VisaBridgeInteractorBuilder {
    private let evmSmartContractInteractor: EVMSmartContractInteractor

    public init(evmSmartContractInteractor: EVMSmartContractInteractor) {
        self.evmSmartContractInteractor = evmSmartContractInteractor
    }

    public func build(for cardAddress: String, logger: VisaLogger) async throws -> VisaBridgeInteractor {
        let logger = InternalLogger(logger: logger)

        var paymentAccount: String?
        logger.debug(subsystem: .bridgeInteractorBuilder, "Start searching PaymentAccount for card with address: \(cardAddress)")
        let registryAddress = VisaUtilities().registryAddress
        logger.debug(subsystem: .bridgeInteractorBuilder, "Requesting PaymentAccount from bridge with address \(registryAddress)")
        let request = VisaSmartContractRequest(
            contractAddress: registryAddress,
            method: GetPaymentAccountByCardMethod(cardWalletAddress: cardAddress)
        )

        do {
            let response = try await evmSmartContractInteractor.ethCall(request: request).async()
            paymentAccount = try AddressParser().parseAddressResponse(response)
            logger.debug(subsystem: .bridgeInteractorBuilder, "PaymentAccount founded: \(paymentAccount ?? .unknown)")
        } catch {
            logger.debug(subsystem: .bridgeInteractorBuilder, "Failed to receive PaymentAccount. Reason: \(error)")
        }

        guard let paymentAccount else {
            logger.debug(subsystem: .bridgeInteractorBuilder, "No payment account for card address: \(cardAddress)")
            throw VisaBridgeInteractorBuilderError.failedToFindPaymentAccount
        }

        logger.debug(subsystem: .bridgeInteractorBuilder, "Start loading token info")
        let visaToken = try await loadTokenInfo(for: paymentAccount, logger: logger)

        logger.debug(subsystem: .bridgeInteractorBuilder, "Creating Bridge interactor for founded PaymentAccount")
        return CommonBridgeInteractor(
            visaToken: visaToken,
            evmSmartContractInteractor: evmSmartContractInteractor,
            paymentAccount: paymentAccount,
            logger: logger
        )
    }

    private func loadTokenInfo(for paymentAccount: String, logger: InternalLogger) async throws -> Token {
        let contractAddressRequest = VisaSmartContractRequest(contractAddress: paymentAccount, method: GetTokenInfoMethod(infoType: .contractAddress))

        let contractAddress: String
        do {
            let contractAddressResponse = try await evmSmartContractInteractor.ethCall(request: contractAddressRequest).async()
            contractAddress = try AddressParser().parseAddressResponse(contractAddressResponse)
            logger.debug(subsystem: .bridgeInteractorBuilder, "Token contract address loaded and parsed. \n\(contractAddress)")
        } catch {
            logger.debug(subsystem: .bridgeInteractorBuilder, "Failed to load token contract address. Error: \(error)")
            throw error
        }

        do {
            let nameRequest = VisaSmartContractRequest(contractAddress: contractAddress, method: GetTokenInfoMethod(infoType: .name))
            let symbolRequest = VisaSmartContractRequest(contractAddress: contractAddress, method: GetTokenInfoMethod(infoType: .symbol))
            let decimalsRequest = VisaSmartContractRequest(contractAddress: contractAddress, method: GetTokenInfoMethod(infoType: .decimals))

            logger.debug(subsystem: .bridgeInteractorBuilder, "Start loading token name, symbol and decimals")
            async let nameResponse = try evmSmartContractInteractor.ethCall(request: nameRequest).async()
            async let symbolResponse = try evmSmartContractInteractor.ethCall(request: symbolRequest).async()
            async let decimalsResponse = try evmSmartContractInteractor.ethCall(request: decimalsRequest).async()

            let nameData = try await Data(hexString: nameResponse)
            let symbolData = try await Data(hexString: symbolResponse)
            let decimalCount = try await EthereumUtils.parseEthereumDecimal(decimalsResponse, decimalsCount: 0)

            logger.debug(subsystem: .bridgeInteractorBuilder, "Token name, symbol and decimals loaded. Validating data existence and creating Token entity")
            guard
                let name = String(data: nameData, encoding: .utf8),
                let symbol = String(data: symbolData, encoding: .utf8),
                let decimalCount
            else {
                logger.debug(subsystem: .bridgeInteractorBuilder, "Failed to convert loaded token name or symbol")
                throw VisaBridgeInteractorBuilderError.failedToLoadTokenInfo
            }

            let token = Token(
                name: cleanUpString(name),
                symbol: cleanUpString(symbol),
                contractAddress: contractAddress,
                decimalCount: decimalCount.decimalNumber.intValue,
                id: VisaUtilities().tokenId
            )
            logger.debug(subsystem: .bridgeInteractorBuilder, "Token info loaded and converted to entity. Token info:\n\(token)")

            return token
        } catch {
            logger.debug(subsystem: .bridgeInteractorBuilder, "Failed to load Token info. Error: \(error)")
            throw error
        }
    }

    private func cleanUpString(_ string: String) -> String {
        // We need to remove all null characters before usage.
        // For some reason, the smart contract sends strings cluttered with null characters.
        string.trimmingCharacters(in: .whitespacesAndNewlines.union(["\0"]))
    }
}

public extension VisaBridgeInteractorBuilder {
    enum VisaBridgeInteractorBuilderError: String, LocalizedError {
        case failedToFindPaymentAccount
        case failedToLoadTokenInfo

        public var errorDescription: String? {
            rawValue
        }
    }
}

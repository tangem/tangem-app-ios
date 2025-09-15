//
//  VisaTokenInfoLoader.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemFoundation

/// Responsible for loading Visa token information from the blockchain using smart contract calls.
/// Retrieves token name, symbol, decimals, and contract address.
struct VisaTokenInfoLoader {
    private let isTestnet: Bool
    private let evmSmartContractInteractor: EVMSmartContractInteractor

    init(isTestnet: Bool, evmSmartContractInteractor: EVMSmartContractInteractor) {
        self.isTestnet = isTestnet
        self.evmSmartContractInteractor = evmSmartContractInteractor
    }

    /// Loads token information for a given payment account address.
    /// - Parameter paymentAccount: The address of the Visa payment account.
    /// - Returns: A `Token` instance containing the name, symbol, decimals, and contract address.
    /// - Throws: An error if any part of the token information cannot be retrieved.
    func loadTokenInfo(for paymentAccount: String) async throws -> Token {
        let contractAddress = try await loadContractAddress(for: paymentAccount)

        async let name = try loadText(for: contractAddress, requestType: .name)
        async let symbol = try loadText(for: contractAddress, requestType: .symbol)
        async let decimalsCount = try loadDecimalsCount(contractAddress: contractAddress)

        return try await .init(
            name: name,
            symbol: symbol,
            contractAddress: contractAddress,
            decimalCount: decimalsCount,
            id: VisaUtilities.tokenId
        )
    }

    /// Loads the contract address associated with a Visa payment account.
    /// - Parameter paymentAccount: The address of the Visa payment account.
    /// - Returns: The contract address as a `String`.
    /// - Throws: An error  if the contract address cannot be retrieved or parsed.
    private func loadContractAddress(for paymentAccount: String) async throws -> String {
        let contractAddressRequest = VisaSmartContractRequest(contractAddress: paymentAccount, method: GetTokenInfoMethod(infoType: .contractAddress))

        do {
            let contractAddressResponse = try await evmSmartContractInteractor.ethCall(request: contractAddressRequest).async()
            let contractAddress = try AddressParser(isTestnet: isTestnet).parseAddressResponse(contractAddressResponse)
            VisaLogger.info("Token contract address loaded and parsed successfully")
            return contractAddress
        } catch {
            VisaLogger.error("Failed to load token contract address", error: error)
            throw LoaderError.failedToLoadInfo(method: .contractAddress)
        }
    }

    /// Loads the number of decimal places for a token from its contract.
    /// - Parameter contractAddress: The token contract address.
    /// - Returns: The token's decimal count.
    /// - Throws: An error if the decimal information is not valid.
    private func loadDecimalsCount(contractAddress: String) async throws -> Int {
        let request = VisaSmartContractRequest(contractAddress: contractAddress, method: GetTokenInfoMethod(infoType: .decimals))
        let response = try await evmSmartContractInteractor.ethCall(request: request).async()

        guard let decimals = EthereumUtils.parseEthereumDecimal(response, decimalsCount: 0) else {
            throw LoaderError.failedToLoadInfo(method: .decimals)
        }

        return decimals.decimalNumber.intValue
    }

    /// Loads a text value (name or symbol) from the token contract.
    /// - Parameters:
    ///   - contractAddress: The token contract address.
    ///   - requestType: The type of token information to retrieve (`.name` or `.symbol`).
    /// - Returns: The text string for the requested info type.
    /// - Throws: An error with specified failed method.
    private func loadText(for contractAddress: String, requestType: GetTokenInfoMethod.InfoType) async throws -> String {
        let request = VisaSmartContractRequest(contractAddress: contractAddress, method: GetTokenInfoMethod(infoType: requestType))
        let response = try await evmSmartContractInteractor.ethCall(request: request).async()
        let textData = Data(hexString: response)

        guard let text = String(data: textData, encoding: .utf8) else {
            throw LoaderError.failedToLoadInfo(method: requestType)
        }

        return trimSpacesAndNullCharacter(text)
    }

    /// Trims spaces and null characters from a blockchain-returned string.
    /// - Parameter string: The raw string from the contract.
    /// - Returns: A cleaned string with extraneous whitespace and null characters removed.
    private func trimSpacesAndNullCharacter(_ string: String) -> String {
        // We need to remove all null characters before usage.
        // For some reason, the smart contract sends strings cluttered with null characters.
        string.trimmingCharacters(in: .whitespacesAndNewlines.union(["\0"]))
    }
}

extension VisaTokenInfoLoader {
    /// Represents an error that occurs when token info cannot be loaded from the blockchain.
    enum LoaderError {
        /// Indicates a failure to load specific token information.
        case failedToLoadInfo(method: GetTokenInfoMethod.InfoType)
    }
}

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

struct VisaTokenInfoLoader {
    private let isTestnet: Bool
    private let evmSmartContractInteractor: EVMSmartContractInteractor

    init(isTestnet: Bool, evmSmartContractInteractor: EVMSmartContractInteractor) {
        self.isTestnet = isTestnet
        self.evmSmartContractInteractor = evmSmartContractInteractor
    }

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
            id: VisaUtilities(isTestnet: isTestnet).tokenId
        )
    }

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

    private func loadDecimalsCount(contractAddress: String) async throws -> Int {
        let request = VisaSmartContractRequest(contractAddress: contractAddress, method: GetTokenInfoMethod(infoType: .decimals))
        let response = try await evmSmartContractInteractor.ethCall(request: request).async()

        guard let decimals = EthereumUtils.parseEthereumDecimal(response, decimalsCount: 0) else {
            throw LoaderError.failedToLoadInfo(method: .decimals)
        }

        return decimals.decimalNumber.intValue
    }

    private func loadText(for contractAddress: String, requestType: GetTokenInfoMethod.InfoType) async throws -> String {
        let request = VisaSmartContractRequest(contractAddress: contractAddress, method: GetTokenInfoMethod(infoType: requestType))
        let response = try await evmSmartContractInteractor.ethCall(request: request).async()
        let textData = Data(hexString: response)

        guard let text = String(data: textData, encoding: .utf8) else {
            throw LoaderError.failedToLoadInfo(method: requestType)
        }

        return trimSpacesAndNullCharacter(text)
    }

    private func trimSpacesAndNullCharacter(_ string: String) -> String {
        // We need to remove all null characters before usage.
        // For some reason, the smart contract sends strings cluttered with null characters.
        string.trimmingCharacters(in: .whitespacesAndNewlines.union(["\0"]))
    }
}

extension VisaTokenInfoLoader {
    enum LoaderError {
        case failedToLoadInfo(method: GetTokenInfoMethod.InfoType)
    }
}

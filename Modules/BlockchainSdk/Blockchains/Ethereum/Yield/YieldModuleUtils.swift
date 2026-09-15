//
//  YieldModuleUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum YieldModuleUtils {
    static func parseEthereumAddress(_ string: String) -> String? {
        let noHexPrefixString = string.removeHexPrefix()
        let ethereumAddressLength = 40

        guard noHexPrefixString.count >= ethereumAddressLength else {
            return nil
        }

        let addressPart = String(noHexPrefixString.suffix(ethereumAddressLength))

        guard !addressPart.allSatisfy({ $0 == "0" }), addressPart.allSatisfy(\.isHexDigit) else {
            return nil
        }

        return addressPart.addHexPrefix()
    }

    static func resolveConsistentEthereumAddress(from results: [Result<String, Error>]) throws -> String {
        var addresses: [String] = []
        var firstError: Error?

        for result in results {
            switch result {
            case .success(let response):
                if let address = parseEthereumAddress(response) {
                    addresses.append(address)
                } else if !isZeroEthereumAddress(response) {
                    throw YieldModuleError.unableToParseData
                }
            case .failure(let error):
                firstError = firstError ?? error
            }
        }

        guard let address = addresses.first else {
            if let firstError {
                throw firstError
            }

            throw YieldModuleError.noYieldContractFound
        }

        guard addresses.dropFirst().allSatisfy({ $0.caseInsensitiveEquals(to: address) }) else {
            throw YieldModuleError.inconsistentState
        }

        return address
    }

    private static func isZeroEthereumAddress(_ string: String) -> Bool {
        let value = string.removeHexPrefix()
        let ethereumAddressLength = 40

        guard value.count >= ethereumAddressLength, value.allSatisfy(\.isHexDigit) else {
            return false
        }

        return value.suffix(ethereumAddressLength).allSatisfy { $0 == "0" }
    }
}

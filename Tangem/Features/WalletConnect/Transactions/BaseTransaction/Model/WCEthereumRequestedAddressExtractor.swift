//
//  WCEthereumRequestedAddressExtractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum WCEthereumRequestedAddressExtractor {
    static func extract(from transactionData: WCHandleTransactionData) -> String? {
        switch transactionData.method {
        case .sendTransaction, .signTransaction:
            if let transactions = try? JSONDecoder().decode([WalletConnectEthTransaction].self, from: transactionData.requestData) {
                return transactions.first?.from
            }

            let transaction = try? JSONDecoder().decode(WalletConnectEthTransaction.self, from: transactionData.requestData)
            return transaction?.from
        case .personalSign:
            guard let params = parseStringParameters(from: transactionData.rawTransaction), params.count > 1 else {
                return nil
            }

            return params[1]
        case .signTypedData, .signTypedDataV4:
            guard let params = parseStringParameters(from: transactionData.rawTransaction), !params.isEmpty else {
                return nil
            }

            return params[0]
        default:
            return nil
        }
    }

    private static func parseStringParameters(from rawTransaction: String?) -> [String]? {
        guard
            let rawTransaction,
            let data = rawTransaction.data(using: .utf8),
            let parameters = try? JSONDecoder().decode([String].self, from: data)
        else {
            return nil
        }

        return parameters
    }

    static func normalizeAddress(_ address: String) -> String {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let isEvmAddress = trimmedAddress.hasHexPrefix()
            && trimmedAddress.count == 42
            && trimmedAddress.dropFirst(2).allSatisfy(\.isHexDigit)

        return isEvmAddress ? trimmedAddress.lowercased() : trimmedAddress
    }
}

//
//  MainQRDeepLinkPaymentParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct MainQRDeepLinkPaymentParser {
    func parse(
        _ value: String,
        blockchainURIParser: MainQRBlockchainURIParser,
        jsonParser: MainQRJSONPaymentParser
    ) -> MainQRPaymentRequest? {
        guard let components = URLComponents(string: value) else {
            return nil
        }

        let queryItems = components.queryItems?.map { URLQueryItem(name: $0.name.lowercased(), value: $0.value) } ?? []

        if let embeddedValue = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: MainQRParserConstants.embeddedPayloadQueryKeys
        ) {
            let candidates = embeddedPaymentPayloadCandidates(from: embeddedValue)
            for candidate in candidates {
                if let embeddedPayment = blockchainURIParser.parse(candidate) ?? jsonParser.parse(candidate) {
                    return embeddedPayment
                }
            }
        }

        guard
            let rawAddress = MainQRParserSupport.firstQueryValue(
                in: queryItems,
                names: MainQRParserConstants.destinationQueryKeys
            ),
            let chain = MainQRParserSupport.firstQueryValue(
                in: queryItems,
                names: MainQRParserConstants.chainQueryKeys
            ),
            let blockchain = MainQRBlockchainResolver.resolveBlockchain(fromChainName: chain)
        else {
            return nil
        }

        let address = rawAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty, MainQRBlockchainResolver.isValidDestinationAddress(address, for: blockchain) else {
            return nil
        }

        let amountString = MainQRParserSupport.firstQueryValue(in: queryItems, names: MainQRParserConstants.rawAmountQueryKeys)
        let amount = amountString.flatMap(MainQRDecimalParser.parseDecimal)
        let memo = MainQRParserSupport.firstQueryValue(in: queryItems, names: MainQRParserConstants.memoQueryKeys)
        let tokenSymbol = MainQRParserSupport.firstQueryValue(in: queryItems, names: MainQRParserConstants.tokenSymbolQueryKeys)

        let tokenContractAddress = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: MainQRParserConstants.tokenContractQueryKeys
        )

        let knownKeys = Set<String>(
            MainQRParserConstants.embeddedPayloadQueryKeys
                + MainQRParserConstants.destinationQueryKeys
                + MainQRParserConstants.chainQueryKeys
                + MainQRParserConstants.rawAmountQueryKeys
                + MainQRParserConstants.memoQueryKeys
                + MainQRParserConstants.tokenSymbolQueryKeys
                + MainQRParserConstants.tokenContractQueryKeys
        )
        let unknown = MainQRParserSupport.unknownParameters(in: queryItems, knownKeys: knownKeys)

        if !unknown.isEmpty {
            MainQRScanLogger.warning(
                MainQRScanLoggerStrings.unknownQueryParameters(
                    blockchain: blockchain.displayName,
                    parameters: unknown
                )
            )
        }

        return MainQRPaymentRequest(
            blockchain: blockchain,
            destinationAddress: address,
            amount: amount,
            memo: memo,
            tokenSymbol: tokenSymbol,
            tokenContractAddress: tokenContractAddress,
            rawTokenAmount: nil,
            unknownParameters: unknown
        )
    }

    private func embeddedPaymentPayloadCandidates(from value: String) -> [String] {
        let initial = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !initial.isEmpty else {
            return []
        }

        var candidates = [initial]
        var current = initial

        // Some providers percent-encode payload values more than once.
        for _ in 0 ..< 3 {
            guard let decoded = current.removingPercentEncoding else {
                break
            }

            let normalizedDecoded = decoded.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedDecoded.isEmpty, normalizedDecoded != current else {
                break
            }

            current = normalizedDecoded
            if !candidates.contains(normalizedDecoded) {
                candidates.append(normalizedDecoded)
            }
        }

        return candidates
    }
}

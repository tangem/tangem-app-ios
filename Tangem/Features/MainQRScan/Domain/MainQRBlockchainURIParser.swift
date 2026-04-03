//
//  MainQRBlockchainURIParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct MainQRBlockchainURIParser {
    private let eip681Parser: MainQREIP681Parser
    private let tronBuilder: MainQRBlockchainURIRequestBuilder = MainQRTronURIRequestBuilder()
    private let defaultBuilder: MainQRBlockchainURIRequestBuilder = MainQRDefaultURIRequestBuilder()

    init(eip681Parser: MainQREIP681Parser = MainQREIP681Parser()) {
        self.eip681Parser = eip681Parser
    }

    func parse(_ value: String) -> MainQRPaymentRequest? {
        let lowercasedValue = value.lowercased()

        let ethereumPrefixes = Blockchain.ethereum(testnet: false).qrPrefixes
        if MainQRParserSupport.hasPrefix(lowercasedValue, in: ethereumPrefixes) {
            return eip681Parser.parse(value)
        }

        for blockchain in Blockchain.allMainnetCases {
            guard MainQRParserSupport.hasPrefix(lowercasedValue, in: blockchain.qrPrefixes) else {
                continue
            }

            let parser = QRCodeParser(
                amountType: .coin,
                blockchain: blockchain,
                decimalCount: blockchain.decimalCount
            )

            guard let parsed = parser.parse(value) else {
                continue
            }

            guard MainQRBlockchainResolver.isValidDestinationAddress(parsed.destination, for: blockchain) else {
                continue
            }

            let queryItems = MainQRParserSupport.queryItems(from: value)
            let builder = requestBuilder(for: blockchain)

            let request = builder.buildRequest(
                blockchain: blockchain,
                destination: parsed.destination,
                parsedAmount: parsed.amount?.value,
                parsedMemo: parsed.memo,
                queryItems: queryItems
            )

            logUnknownParametersIfNeeded(request: request, blockchain: blockchain)

            return request
        }

        return parseGenericBlockchainURI(value)
    }

    // MARK: - Private

    private func requestBuilder(for blockchain: Blockchain) -> MainQRBlockchainURIRequestBuilder {
        switch blockchain {
        case .tron:
            return tronBuilder
        default:
            return defaultBuilder
        }
    }

    private func parseGenericBlockchainURI(_ value: String) -> MainQRPaymentRequest? {
        guard
            let schemeSeparator = value.firstIndex(of: ":"),
            schemeSeparator > value.startIndex
        else {
            return nil
        }

        let scheme = String(value[..<schemeSeparator])
        guard
            MainQRParserSupport.normalizeQueryKey(scheme) != MainQRParserConstants.walletConnectSchemeName,
            let blockchain = MainQRBlockchainResolver.resolveBlockchain(fromChainName: scheme)
        else {
            return nil
        }

        var payload = String(value[value.index(after: schemeSeparator)...])
        if payload.hasPrefix("//") {
            payload.removeFirst(2)
        }

        let parts = payload.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        var pathPart = String(parts.first ?? "")
        let queryPart = parts.count > 1 ? String(parts[1]) : ""
        let queryItems = MainQRParserSupport.queryItems(fromRawQuery: queryPart)

        if MainQRParserSupport.hasPrefix(pathPart, in: [MainQRParserConstants.genericTransferPrefix]) {
            pathPart.removeFirst(MainQRParserConstants.genericTransferPrefix.count)
        }

        if pathPart.contains("/") {
            pathPart = String(pathPart.split(separator: "/").last ?? "")
        }

        let destination = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: MainQRParserConstants.destinationQueryKeys
        ) ?? pathPart
        let destinationAddress = destination.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            !destinationAddress.isEmpty,
            MainQRBlockchainResolver.isValidDestinationAddress(destinationAddress, for: blockchain)
        else {
            return nil
        }

        let rawAmount = MainQRParserSupport.firstQueryValue(in: queryItems, names: MainQRParserConstants.rawAmountQueryKeys)
        let amount = rawAmount.flatMap(MainQRDecimalParser.parseDecimal)
        let memo = MainQRParserSupport.firstQueryValue(in: queryItems, names: MainQRParserConstants.memoQueryKeys)
        let tokenSymbol = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: MainQRParserConstants.tokenSymbolQueryKeys
        )
        let tokenContractAddress = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: MainQRParserConstants.tokenContractQueryKeys
        )

        let knownKeys = genericKnownKeys
        let unknown = MainQRParserSupport.unknownParameters(in: queryItems, knownKeys: knownKeys)

        let request = MainQRPaymentRequest(
            blockchain: blockchain,
            destinationAddress: destinationAddress,
            amount: amount,
            memo: memo,
            tokenSymbol: tokenSymbol,
            tokenContractAddress: tokenContractAddress,
            rawTokenAmount: nil,
            unknownParameters: unknown
        )

        logUnknownParametersIfNeeded(request: request, blockchain: blockchain)

        return request
    }

    private var genericKnownKeys: Set<String> {
        var keys = Set<String>()
        MainQRParserConstants.rawAmountQueryKeys.forEach { keys.insert($0) }
        MainQRParserConstants.memoQueryKeys.forEach { keys.insert($0) }
        MainQRParserConstants.tokenSymbolQueryKeys.forEach { keys.insert($0) }
        MainQRParserConstants.tokenContractQueryKeys.forEach { keys.insert($0) }
        MainQRParserConstants.destinationQueryKeys.forEach { keys.insert($0) }
        return keys
    }

    private func logUnknownParametersIfNeeded(request: MainQRPaymentRequest, blockchain: Blockchain) {
        guard !request.unknownParameters.isEmpty else {
            return
        }

        MainQRScanLogger.warning(
            MainQRScanLoggerStrings.unknownQueryParameters(
                blockchain: blockchain.displayName,
                parameters: request.unknownParameters
            )
        )
    }
}

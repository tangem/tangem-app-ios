//
//  MainQREIP681Parser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct MainQREIP681Parser {
    /// Parses EIP-681 URIs with support for chain id and token transfer function.
    func parse(_ value: String) -> MainQRPaymentRequest? {
        guard let normalized = MainQRParserSupport.stripEthereumSchemePrefix(from: value) else {
            return nil
        }

        let base = normalized.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let pathPart = String(base.first ?? "")
        let queryPart = base.count > 1 ? String(base[1]) : ""
        let queryItems = MainQRParserSupport.queryItems(fromRawQuery: queryPart)

        let pathChainIdRawValue = MainQRBlockchainResolver.extractChainIdRawValue(fromPath: pathPart)
        let queryChainIdRawValue = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: [MainQRParserConstants.QueryKey.chainId]
        )
        let chainIdRawValue = pathChainIdRawValue ?? queryChainIdRawValue

        let blockchain: Blockchain
        if let chainIdRawValue {
            guard
                let chainId = Int(chainIdRawValue),
                let resolvedBlockchain = MainQRBlockchainResolver.resolveEVMBlockchain(chainId: chainId)
            else {
                return nil
            }

            blockchain = resolvedBlockchain
        } else {
            blockchain = .ethereum(testnet: false)
        }

        let pathWithoutChain = MainQRBlockchainResolver.stripChainId(pathPart)
        let contractOrAddress = String(
            pathWithoutChain.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
        )

        let isTokenTransfer = pathWithoutChain.lowercased().contains(MainQRParserConstants.eip681TransferPath)
        if isTokenTransfer {
            return parseTokenTransfer(
                queryItems: queryItems,
                blockchain: blockchain,
                contractOrAddress: contractOrAddress
            )
        }

        return parseCoinTransfer(
            value: value,
            queryItems: queryItems,
            blockchain: blockchain,
            pathWithoutChain: pathWithoutChain
        )
    }

    private func parseTokenTransfer(
        queryItems: [URLQueryItem],
        blockchain: Blockchain,
        contractOrAddress: String
    ) -> MainQRPaymentRequest? {
        guard
            let destination = MainQRParserSupport.firstQueryValue(
                in: queryItems,
                names: [MainQRParserConstants.QueryKey.address]
            ),
            !destination.isEmpty,
            MainQRBlockchainResolver.isValidDestinationAddress(destination, for: blockchain)
        else {
            return nil
        }

        let memo = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: MainQRParserConstants.eip681TransferMemoQueryKeys
        )
        let tokenSymbol = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: MainQRParserConstants.tokenSymbolQueryKeys
        )

        let rawTokenAmount = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: MainQRParserConstants.eip681TransferAmountQueryKeys
        ).flatMap(MainQRDecimalParser.parseDecimal)

        let knownKeys: Set<String> = Set(
            [MainQRParserConstants.QueryKey.address, MainQRParserConstants.QueryKey.chainId]
                + MainQRParserConstants.eip681TransferMemoQueryKeys
                + MainQRParserConstants.tokenSymbolQueryKeys
                + MainQRParserConstants.eip681TransferAmountQueryKeys
        )
        let unknown = MainQRParserSupport.unknownParameters(in: queryItems, knownKeys: knownKeys)

        let request = MainQRPaymentRequest(
            blockchain: blockchain,
            destinationAddress: destination,
            amount: nil,
            memo: memo,
            tokenSymbol: tokenSymbol,
            tokenContractAddress: contractOrAddress,
            rawTokenAmount: rawTokenAmount,
            unknownParameters: unknown
        )

        logUnknownParametersIfNeeded(request: request, blockchain: blockchain)

        return request
    }

    private func parseCoinTransfer(
        value: String,
        queryItems: [URLQueryItem],
        blockchain: Blockchain,
        pathWithoutChain: String
    ) -> MainQRPaymentRequest? {
        let parser = QRCodeParser(
            amountType: .coin,
            blockchain: blockchain,
            decimalCount: blockchain.decimalCount
        )
        let parsed = parser.parse(value)

        let destinationCandidate = String(
            pathWithoutChain.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: true).first ?? ""
        )
        let destination = destinationCandidate.nilIfEmpty ?? parsed?.destination ?? ""

        guard !destination.isEmpty else {
            return nil
        }

        guard MainQRBlockchainResolver.isValidDestinationAddress(destination, for: blockchain) else {
            return nil
        }

        let knownKeys: Set<String> = Set(
            [MainQRParserConstants.QueryKey.chainId]
                + MainQRParserConstants.eip681AmountQueryKeys
                + MainQRParserConstants.eip681TransferMemoQueryKeys
                + MainQRParserConstants.tokenSymbolQueryKeys
        )
        let unknown = MainQRParserSupport.unknownParameters(in: queryItems, knownKeys: knownKeys)

        let request = MainQRPaymentRequest(
            blockchain: blockchain,
            destinationAddress: destination,
            amount: resolveAmount(
                rawAmount: MainQRParserSupport.firstQueryValue(
                    in: queryItems,
                    names: MainQRParserConstants.eip681AmountQueryKeys
                ),
                parsedAmount: parsed?.amount?.value
            ),
            memo: parsed?.memo ?? MainQRParserSupport.firstQueryValue(
                in: queryItems,
                names: MainQRParserConstants.eip681TransferMemoQueryKeys
            ),
            tokenSymbol: MainQRParserSupport.firstQueryValue(
                in: queryItems,
                names: MainQRParserConstants.tokenSymbolQueryKeys
            ),
            tokenContractAddress: nil,
            rawTokenAmount: nil,
            unknownParameters: unknown
        )

        logUnknownParametersIfNeeded(request: request, blockchain: blockchain)

        return request
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

    private func resolveAmount(rawAmount: String?, parsedAmount: Decimal?) -> Decimal? {
        // If QRCodeParser has already produced a scaled amount, prefer it and
        // avoid overriding it with a differently interpreted raw value.
        if let parsedAmount {
            return parsedAmount
        }

        guard let trimmedRawAmount = rawAmount?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmedRawAmount.isEmpty else {
            return nil
        }

        if trimmedRawAmount.contains(".") || trimmedRawAmount.contains(",") {
            return MainQRDecimalParser.parseDecimal(trimmedRawAmount)
        }

        return MainQRDecimalParser.parseDecimal(trimmedRawAmount)
    }
}

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
    func parse(_ value: String) -> MainQRPaymentRequest? {
        let lowercasedValue = value.lowercased()

        let ethereumPrefixes = Blockchain.ethereum(testnet: false).qrPrefixes
        if ethereumPrefixes.contains(where: { lowercasedValue.hasPrefix($0.lowercased()) }) {
            return parseEIP681(value)
        }

        for blockchain in Blockchain.allMainnetCases {
            guard blockchain.qrPrefixes.contains(where: { lowercasedValue.hasPrefix($0.lowercased()) }) else {
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

            guard MainQRParserSupport.isValidDestinationAddress(parsed.destination, for: blockchain) else {
                continue
            }

            let queryItems = MainQRParserSupport.queryItems(from: value)

            return MainQRPaymentRequest(
                blockchain: blockchain,
                destinationAddress: parsed.destination,
                amount: parsed.amount?.value,
                rawAmount: MainQRParserSupport.firstQueryValue(
                    in: queryItems,
                    names: MainQRParserConstants.rawAmountQueryKeys
                ),
                memo: parsed.memo ?? MainQRParserSupport.firstQueryValue(
                    in: queryItems,
                    names: MainQRParserConstants.memoQueryKeys
                ),
                tokenContractAddress: nil
            )
        }

        return parseGenericBlockchainURI(value)
    }

    /// Parses EIP-681 URIs with support for chain id and token transfer function.
    private func parseEIP681(_ value: String) -> MainQRPaymentRequest? {
        guard let normalized = MainQRParserSupport.stripEthereumSchemePrefix(from: value) else {
            return nil
        }

        let base = normalized.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let pathPart = String(base.first ?? "")
        let queryPart = base.count > 1 ? String(base[1]) : ""
        let queryItems = MainQRParserSupport.queryItems(fromRawQuery: queryPart)

        let pathChainIdRawValue = MainQRParserSupport.extractChainIdRawValue(fromPath: pathPart)
        let queryChainIdRawValue = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: [MainQRParserConstants.QueryKey.chainId]
        )
        let chainIdRawValue = pathChainIdRawValue ?? queryChainIdRawValue

        let blockchain: Blockchain
        if let chainIdRawValue {
            guard
                let chainId = Int(chainIdRawValue),
                let resolvedBlockchain = MainQRParserSupport.resolveEVMBlockchain(chainId: chainId)
            else {
                return nil
            }

            blockchain = resolvedBlockchain
        } else {
            blockchain = .ethereum(testnet: false)
        }

        let pathWithoutChain = MainQRParserSupport.stripChainId(pathPart)
        let contractOrAddress = String(
            pathWithoutChain.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
        )

        let isTokenTransfer = pathWithoutChain.lowercased().contains(MainQRParserConstants.eip681TransferPath)
        if isTokenTransfer {
            guard
                let destination = MainQRParserSupport.firstQueryValue(
                    in: queryItems,
                    names: [MainQRParserConstants.QueryKey.address]
                ),
                !destination.isEmpty,
                MainQRParserSupport.isValidDestinationAddress(destination, for: blockchain)
            else {
                return nil
            }

            let rawAmount = MainQRParserSupport.firstQueryValue(
                in: queryItems,
                names: MainQRParserConstants.eip681TransferAmountQueryKeys
            )
            let memo = MainQRParserSupport.firstQueryValue(
                in: queryItems,
                names: MainQRParserConstants.eip681TransferMemoQueryKeys
            )

            return MainQRPaymentRequest(
                blockchain: blockchain,
                destinationAddress: destination,
                amount: nil,
                rawAmount: rawAmount,
                memo: memo,
                tokenContractAddress: contractOrAddress
            )
        }

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

        guard MainQRParserSupport.isValidDestinationAddress(destination, for: blockchain) else {
            return nil
        }

        return MainQRPaymentRequest(
            blockchain: blockchain,
            destinationAddress: destination,
            amount: parsed?.amount?.value,
            rawAmount: MainQRParserSupport.firstQueryValue(
                in: queryItems,
                names: MainQRParserConstants.eip681AmountQueryKeys
            ),
            memo: parsed?.memo ?? MainQRParserSupport.firstQueryValue(
                in: queryItems,
                names: MainQRParserConstants.eip681TransferMemoQueryKeys
            ),
            tokenContractAddress: nil
        )
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
            MainQRParserSupport.normalizeQueryName(scheme) != MainQRParserConstants.walletConnectSchemeName,
            let blockchain = MainQRParserSupport.resolveBlockchain(fromChainName: scheme)
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
            MainQRParserSupport.isValidDestinationAddress(destinationAddress, for: blockchain)
        else {
            return nil
        }

        let rawAmount = MainQRParserSupport.firstQueryValue(in: queryItems, names: MainQRParserConstants.rawAmountQueryKeys)
        let amount = rawAmount.flatMap(MainQRParserSupport.parseDecimal)
        let memo = MainQRParserSupport.firstQueryValue(in: queryItems, names: MainQRParserConstants.memoQueryKeys)
        let tokenContractAddress = MainQRParserSupport.firstQueryValue(
            in: queryItems,
            names: MainQRParserConstants.tokenContractQueryKeys
        )

        return MainQRPaymentRequest(
            blockchain: blockchain,
            destinationAddress: destinationAddress,
            amount: amount,
            rawAmount: rawAmount,
            memo: memo,
            tokenContractAddress: tokenContractAddress
        )
    }
}

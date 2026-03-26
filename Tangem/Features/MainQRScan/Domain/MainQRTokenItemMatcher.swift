//
//  MainQRTokenItemMatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct MainQRTokenItemMatcher {
    func matchTokenItems(
        for request: MainQRPaymentRequest,
        availableTokenItems: [TokenItem],
        availableBlockchains: [Blockchain]
    ) -> [TokenItem] {
        let trimmedContractAddress = request.tokenContractAddress?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
        let normalizedSymbol = request.tokenSymbol?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
            .map(MainQRParserSupport.normalizeIdentifier)

        MainQRScanLogger.debug(
            "[TokenItemMatcher] blockchain=\(request.blockchain), contract=\(trimmedContractAddress ?? "nil"), symbol=\(normalizedSymbol ?? "nil")"
        )

        let sameBlockchainItems = availableTokenItems.filter { $0.blockchain == request.blockchain }
        for item in sameBlockchainItems {
            MainQRScanLogger.debug(
                "[TokenItemMatcher] available: \(item.currencySymbol) contract=\(item.contractAddress ?? "coin")"
            )
        }

        if let result = matchByContractAddress(trimmedContractAddress, blockchain: request.blockchain, availableTokenItems: availableTokenItems) {
            MainQRScanLogger.debug("[TokenItemMatcher] matched by contract address: \(result.count) items")
            return result
        }

        if let result = matchBySymbol(normalizedSymbol: normalizedSymbol, contractAddressForSymbolFallback: trimmedContractAddress, blockchain: request.blockchain, availableTokenItems: availableTokenItems) {
            MainQRScanLogger.debug("[TokenItemMatcher] matched by symbol: \(result.count) items")
            return result
        }

        let hasSpecificToken = trimmedContractAddress != nil || normalizedSymbol != nil
        if hasSpecificToken {
            MainQRScanLogger.debug("[TokenItemMatcher] specific token requested but not found, returning empty")
            return []
        }

        let fallback = matchByCoinOrSynthetic(blockchain: request.blockchain, availableTokenItems: availableTokenItems, availableBlockchains: availableBlockchains)
        MainQRScanLogger.debug("[TokenItemMatcher] fallback to native coin: \(fallback.count) items")
        return fallback
    }

    // MARK: - Private

    private func matchByContractAddress(
        _ contractAddress: String?,
        blockchain: Blockchain,
        availableTokenItems: [TokenItem]
    ) -> [TokenItem]? {
        guard
            let contractAddress,
            MainQRBlockchainResolver.isValidDestinationAddress(contractAddress, for: blockchain)
        else {
            return nil
        }

        let isHexLike = contractAddress.hasPrefix("0x") || contractAddress.hasPrefix("0X")

        let matched = availableTokenItems.filter { item in
            guard
                item.blockchain == blockchain,
                let itemContractAddress = item.contractAddress
            else {
                return false
            }

            if isHexLike {
                return itemContractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame
            } else {
                return itemContractAddress == contractAddress
            }
        }

        return matched.isEmpty ? nil : matched
    }

    /// Falls back to contract address as symbol — some QR formats put the symbol in the contract address field
    private func matchBySymbol(
        normalizedSymbol: String?,
        contractAddressForSymbolFallback: String?,
        blockchain: Blockchain,
        availableTokenItems: [TokenItem]
    ) -> [TokenItem]? {
        guard let symbol = normalizedSymbol ?? contractAddressForSymbolFallback.map(MainQRParserSupport.normalizeIdentifier) else {
            return nil
        }

        let matched = availableTokenItems.filter {
            $0.blockchain == blockchain
                && MainQRParserSupport.normalizeIdentifier($0.currencySymbol) == symbol
        }

        return matched.isEmpty ? nil : matched
    }

    /// When no token is specified, returns the native coin for this blockchain.
    private func matchByCoinOrSynthetic(
        blockchain: Blockchain,
        availableTokenItems: [TokenItem],
        availableBlockchains: [Blockchain]
    ) -> [TokenItem] {
        let sameBlockchainItems = availableTokenItems.filter { $0.blockchain == blockchain }

        if sameBlockchainItems.isEmpty {
            return availableBlockchains
                .filter { $0 == blockchain }
                .map { TokenItem.blockchain(BlockchainNetwork($0, derivationPath: nil)) }
        }

        let coinItems = sameBlockchainItems.filter(\.isBlockchain)
        return coinItems.isEmpty ? sameBlockchainItems : coinItems
    }
}

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

        if let result = matchByContractAddress(trimmedContractAddress, blockchain: request.blockchain, availableTokenItems: availableTokenItems) {
            return result
        }

        if let result = matchBySymbol(normalizedSymbol: normalizedSymbol, contractAddressForSymbolFallback: trimmedContractAddress, blockchain: request.blockchain, availableTokenItems: availableTokenItems) {
            return result
        }

        return matchByCoinOrSynthetic(blockchain: request.blockchain, availableTokenItems: availableTokenItems, availableBlockchains: availableBlockchains)
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

        return availableTokenItems.filter { item in
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

        return availableTokenItems.filter {
            $0.blockchain == blockchain
                && MainQRParserSupport.normalizeIdentifier($0.currencySymbol) == symbol
        }
    }

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

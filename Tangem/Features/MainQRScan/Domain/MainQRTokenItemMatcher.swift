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
        let normalizedContractAddress = request.tokenContractAddress?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
            .map { $0.lowercased() }
        let normalizedSymbol = request.tokenSymbol?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
            .map(MainQRParserSupport.normalizeIdentifier)

        if let result = matchByContractAddress(normalizedContractAddress, blockchain: request.blockchain, availableTokenItems: availableTokenItems) {
            return result
        }

        if let result = matchBySymbol(normalizedSymbol: normalizedSymbol, normalizedContractAddress: normalizedContractAddress, blockchain: request.blockchain, availableTokenItems: availableTokenItems) {
            return result
        }

        return matchByCoinOrSynthetic(blockchain: request.blockchain, availableTokenItems: availableTokenItems, availableBlockchains: availableBlockchains)
    }

    // MARK: - Private

    private func matchByContractAddress(
        _ normalizedContractAddress: String?,
        blockchain: Blockchain,
        availableTokenItems: [TokenItem]
    ) -> [TokenItem]? {
        guard
            let normalizedContractAddress,
            MainQRBlockchainResolver.isValidDestinationAddress(normalizedContractAddress, for: blockchain)
        else {
            return nil
        }

        return availableTokenItems.filter {
            $0.blockchain == blockchain
                && $0.contractAddress?.lowercased() == normalizedContractAddress
        }
    }

    /// Falls back to contract address as symbol — some QR formats put the symbol in the contract address field
    private func matchBySymbol(
        normalizedSymbol: String?,
        normalizedContractAddress: String?,
        blockchain: Blockchain,
        availableTokenItems: [TokenItem]
    ) -> [TokenItem]? {
        guard let symbol = normalizedSymbol ?? normalizedContractAddress.map(MainQRParserSupport.normalizeIdentifier) else {
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

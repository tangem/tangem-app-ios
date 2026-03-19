//
//  MainQRBlockchainResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum MainQRBlockchainResolver {
    private static let blockchainAliases: [String: Blockchain] = [
        "eth": .ethereum(testnet: false),
        "ethereum": .ethereum(testnet: false),
        "bnb": .bsc(testnet: false),
        "bsc": .bsc(testnet: false),
        "bnbchain": .bsc(testnet: false),
        "binancesmartchain": .bsc(testnet: false),
        "polygon": .polygon(testnet: false),
        "matic": .polygon(testnet: false),
        "btc": .bitcoin(testnet: false),
        "bitcoin": .bitcoin(testnet: false),
        "trx": .tron(testnet: false),
        "tron": .tron(testnet: false),
        "sol": .solana(curve: .ed25519_slip0010, testnet: false),
        "solana": .solana(curve: .ed25519_slip0010, testnet: false),
        "ton": .ton(curve: .ed25519_slip0010, testnet: false),
        "theopennetwork": .ton(curve: .ed25519_slip0010, testnet: false),
    ]

    static func resolveEVMBlockchain(chainId: Int?) -> Blockchain? {
        guard let chainId else {
            return nil
        }

        return Blockchain.allMainnetCases.first(where: { $0.chainId == chainId })
    }

    static func resolveBlockchain(fromChainName chainName: String) -> Blockchain? {
        let normalized = MainQRParserSupport.normalizeIdentifier(chainName)

        if let aliased = blockchainAliases[normalized] {
            return aliased
        }

        return Blockchain.allMainnetCases.first { blockchain in
            MainQRParserSupport.normalizeIdentifier(blockchain.codingKey) == normalized
                || MainQRParserSupport.normalizeIdentifier(blockchain.displayName) == normalized
                || MainQRParserSupport.normalizeIdentifier(blockchain.currencySymbol) == normalized
        }
    }

    static func extractChainIdRawValue(fromPath path: String) -> String? {
        guard let atIndex = path.firstIndex(of: "@") else {
            return nil
        }

        let chainPart = path[path.index(after: atIndex)...]
        return chainPart
            .split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init)
    }

    static func stripChainId(_ path: String) -> String {
        guard let atIndex = path.firstIndex(of: "@") else {
            return path
        }

        let addressPart = String(path[..<atIndex])
        let afterChainPart = path[path.index(after: atIndex)...]
        let remainder = afterChainPart.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)

        guard remainder.count > 1 else {
            return addressPart
        }

        return "\(addressPart)/\(remainder[1])"
    }

    static func isValidDestinationAddress(_ address: String, for blockchain: Blockchain) -> Bool {
        let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        return addressService.validate(address)
    }
}

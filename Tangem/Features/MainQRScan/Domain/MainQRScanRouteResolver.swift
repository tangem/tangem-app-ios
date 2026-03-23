//
//  MainQRScanRouteResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct MainQRScanRouteResolver {
    private let parser: MainQRCodeContentParser
    private let addressResolver: AddressBlockchainResolver
    private let tokenItemMatcher: MainQRTokenItemMatcher

    init(
        parser: MainQRCodeContentParser = MainQRCodeContentParser(),
        addressResolver: AddressBlockchainResolver = AddressBlockchainResolver(),
        tokenItemMatcher: MainQRTokenItemMatcher = MainQRTokenItemMatcher()
    ) {
        self.parser = parser
        self.addressResolver = addressResolver
        self.tokenItemMatcher = tokenItemMatcher
    }

    func resolve(
        scannedCode: String,
        availableBlockchains: [Blockchain],
        availableTokenItems: [TokenItem] = []
    ) -> MainQRScanAction {
        switch parser.parse(scannedCode) {
        case .walletConnect(let uri):
            return .walletConnect(uri)
        case .paymentURI(let request):
            return actionForPayment(
                request: request,
                availableBlockchains: availableBlockchains,
                availableTokenItems: availableTokenItems
            )
        case .plainAddress(let address):
            return actionForAddress(address: address, availableBlockchains: availableBlockchains)
        case .unrecognized:
            return .showUnrecognized
        }
    }

    private func actionForPayment(
        request: MainQRPaymentRequest,
        availableBlockchains: [Blockchain],
        availableTokenItems: [TokenItem]
    ) -> MainQRScanAction {
        let matchingTokenItems = tokenItemMatcher.matchTokenItems(
            for: request,
            availableTokenItems: availableTokenItems,
            availableBlockchains: availableBlockchains
        )

        guard !matchingTokenItems.isEmpty else {
            return .showNoSupportedTokens(.payment(request))
        }

        let resolvedRequest = MainQRResolvedPaymentRequest(
            request: request,
            matchingTokenItems: matchingTokenItems
        )

        return .payment(resolvedRequest)
    }

    private func actionForAddress(
        address: String,
        availableBlockchains: [Blockchain]
    ) -> MainQRScanAction {
        if availableBlockchains.isEmpty {
            let globallyCompatibleBlockchains = addressResolver.resolve(
                address: address,
                blockchains: Blockchain.allMainnetCases
            )

            if !globallyCompatibleBlockchains.isEmpty {
                MainQRScanLogger.warning(MainQRScanLoggerStrings.addressQRGloballyValidWithoutAvailableBlockchains)
                return .showNoSupportedTokens()
            }
        }

        let compatibleBlockchains = addressResolver.resolve(
            address: address,
            blockchains: availableBlockchains
        )
        let uniqueMatchingBlockchains = orderedUniqueBlockchains(
            from: availableBlockchains.filter { compatibleBlockchains.contains($0) }
        )

        guard !uniqueMatchingBlockchains.isEmpty else {
            return .showUnrecognized
        }

        return .address(MainQRAddressRequest(
            destinationAddress: address,
            matchingBlockchains: uniqueMatchingBlockchains
        ))
    }

    private func orderedUniqueBlockchains(from blockchains: [Blockchain]) -> [Blockchain] {
        var uniqueBlockchains: [Blockchain] = []
        uniqueBlockchains.reserveCapacity(blockchains.count)

        for blockchain in blockchains where !uniqueBlockchains.contains(blockchain) {
            uniqueBlockchains.append(blockchain)
        }

        return uniqueBlockchains
    }
}

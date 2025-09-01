//
//  CommonDeepLinkValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

struct CommonDeepLinkValidatorTests {
    private let validator = CommonDeepLinkValidator()

    // MARK: Token Chart deeplink

    @Test
    func tokenChartWithValidLetters() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "ethereum")
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithValidAtSymbok() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "ethereum@")
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithValidLettersAndNumbers() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "ethereum123")
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithValidLettersAndUnderscores() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "ethereum_123-ethereum")
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithValidLettersAndDots() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "ethereu.ethereum")
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithValidLettersAndNumbersAndHyphen() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "energy-web-token-123")
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithMissingTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .empty
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithInvalidTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "bad token$")
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithCyrillicInvalidTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "токен")
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    // MARK: Staking deeplink

    @Test
    func stakingWithValidTokenIdAndNetworkId() {
        let action = DeeplinkNavigationAction(
            destination: .staking,
            params: .init(tokenId: "solana", networkId: "mainnet-beta")
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func stakingWithValidTokenIdAndNetworkIdWithHyphen() {
        let action = DeeplinkNavigationAction(
            destination: .staking,
            params: .init(tokenId: "dot-token", networkId: "polkadot-network-1")
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func stakingWithMissingTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .staking,
            params: .init(networkId: "mainnet")
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func stakingWithMissingNetworkId() {
        let action = DeeplinkNavigationAction(
            destination: .staking,
            params: .init(tokenId: "avalanche")
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func stakingWithInvalidTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .staking,
            params: .init(tokenId: "avala nche$", networkId: "mainnet")
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func stakingWithInvalidNetworkId() {
        let action = DeeplinkNavigationAction(
            destination: .staking,
            params: .init(tokenId: "avalanche", networkId: "main@net")
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func stakingWithInvalidCyrylicNetworkAndTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .staking,
            params: .init(tokenId: "биткоин", networkId: "биткоин")
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    // MARK: Token deeplink

    @Test
    func tokenWithValidTokenIdAndNetworkId_shouldPass() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(tokenId: "bitcoin", networkId: "mainnet")
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenWithIncomeTransactionTypeAndValidParams_shouldPass() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(type: .incomeTransaction, tokenId: "sol", networkId: "solnet")
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenWithMissingTokenId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(networkId: "mainnet")
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenWithMissingNetworkId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(tokenId: "bitcoin")
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenWithInvalidTokenId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(tokenId: "bad token$", networkId: "mainnet")
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenWithOnrampStatusUpdateAndAllFields_shouldPass() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(
                type: .onrampStatusUpdate,
                tokenId: "btc",
                networkId: "btc-main",
                derivationPath: "m/44'/0'/0'",
                transactionId: "tx123abc"
            )
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenWithSwapStatusUpdateAndAllFields_shouldPass() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(
                type: .swapStatusUpdate,
                tokenId: "dot",
                networkId: "polkadot",
                derivationPath: "m/44'/354'/0'/0",
                transactionId: "tx_swap_001"
            )
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenWithOnrampMissingTransactionId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(
                type: .onrampStatusUpdate,
                tokenId: "btc",
                networkId: "btc-net",
                derivationPath: "m/44'/0'/0'"
                // transactionId missing
            )
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenWithSwapMissingDerivationPath_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(
                type: .swapStatusUpdate,
                tokenId: "dot",
                networkId: "dotnet",
                transactionId: "tx-001"
                // derivationPath missing
            )
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenWithOnrampValidFieldsButInvalidTokenId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(
                type: .onrampStatusUpdate,
                tokenId: "🔥btc", // invalid
                networkId: "btc-main",
                derivationPath: "m/44'/0'/0'",
                transactionId: "tx123"
            )
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    // MARK: - Optional Param Destinations

    let optionalDestinations: [IncomingActionConstants.DeeplinkDestination] = [
        .buy, .link, .sell, .swap, .referral, .markets, .promo,
    ]

    @Test
    func optionalDestinations_withValidParams_shouldPass() {
        for destination in optionalDestinations {
            let action = DeeplinkNavigationAction(
                destination: destination,
                params: .init(tokenId: "valid123", networkId: "net-456")
            )
            #expect(validator.hasMinimumDataForHandling(deeplink: action))
        }
    }

    @Test
    func optionalDestinations_withInvalidTokenId_shouldFail() {
        for destination in optionalDestinations {
            let action = DeeplinkNavigationAction(
                destination: destination,
                params: .init(tokenId: "🔥", networkId: "net")
            )
            #expect(!validator.hasMinimumDataForHandling(deeplink: action))
        }
    }

    @Test
    func optionalDestinations_withNoParams_shouldPass() {
        for destination in optionalDestinations {
            let action = DeeplinkNavigationAction(
                destination: destination,
                params: .empty
            )
            #expect(validator.hasMinimumDataForHandling(deeplink: action))
        }
    }
}

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
            params: .init(tokenId: "ethereum"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithValidAtSymbol() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "ethereum@"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithValidLettersAndNumbers() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "ethereum123"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithValidLettersAndUnderscores() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "ethereum_123-ethereum"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithValidLettersAndDots() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "ethereu.ethereum"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithValidLettersAndNumbersAndHyphen() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "energy-web-token-123"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithMissingTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .empty,
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithInvalidTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "bad token$"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenChartWithInvalidCharacterTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .tokenChart,
            params: .init(tokenId: "token#invalid"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    // MARK: Token Exchanges deeplink

    @Test
    func tokenExchangesWithValidLetters() {
        let action = DeeplinkNavigationAction(
            destination: .tokenExchanges,
            params: .init(tokenId: "ethereum"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenExchangesWithMissingTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .tokenExchanges,
            params: .empty,
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenExchangesWithInvalidTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .tokenExchanges,
            params: .init(tokenId: "bad token$"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenExchangesWithInvalidCharacterTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .tokenExchanges,
            params: .init(tokenId: "token#invalid"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    // MARK: Staking deeplink

    @Test
    func stakingWithValidTokenIdAndNetworkId() {
        let action = DeeplinkNavigationAction(
            destination: .staking,
            params: .init(tokenId: "solana", networkId: "mainnet-beta"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func stakingWithValidTokenIdAndNetworkIdWithHyphen() {
        let action = DeeplinkNavigationAction(
            destination: .staking,
            params: .init(tokenId: "dot-token", networkId: "polkadot-network-1"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func stakingWithMissingTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .staking,
            params: .init(networkId: "mainnet"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func stakingWithMissingNetworkId() {
        let action = DeeplinkNavigationAction(
            destination: .staking,
            params: .init(tokenId: "avalanche"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func stakingWithInvalidTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .staking,
            params: .init(tokenId: "avala nche$", networkId: "mainnet"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func stakingWithInvalidNetworkId() {
        let action = DeeplinkNavigationAction(
            destination: .staking,
            params: .init(tokenId: "avalanche", networkId: "main@net"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func stakingWithInvalidCharacterTokenAndNetworkId() {
        let action = DeeplinkNavigationAction(
            destination: .staking,
            params: .init(tokenId: "token#invalid", networkId: "net#invalid"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    // MARK: Yield deeplink

    @Test
    func yieldWithValidTokenIdAndNetworkId() {
        let action = DeeplinkNavigationAction(
            destination: .yield,
            params: .init(tokenId: "usd-coin", networkId: "base"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func yieldWithMissingTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .yield,
            params: .init(networkId: "base"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func yieldWithMissingNetworkId() {
        let action = DeeplinkNavigationAction(
            destination: .yield,
            params: .init(tokenId: "usd-coin"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func yieldWithInvalidTokenId() {
        let action = DeeplinkNavigationAction(
            destination: .yield,
            params: .init(tokenId: "usd coin$", networkId: "base"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func yieldWithInvalidCharacterTokenAndNetworkId() {
        let action = DeeplinkNavigationAction(
            destination: .yield,
            params: .init(tokenId: "token#invalid", networkId: "net#invalid"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    // MARK: Token deeplink

    @Test
    func tokenWithValidTokenIdAndNetworkId_shouldPass() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(tokenId: "bitcoin", networkId: "mainnet"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenWithIncomeTransactionTypeAndValidParams_shouldPass() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(type: .incomeTransaction, tokenId: "sol", networkId: "solnet"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenWithMissingTokenId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(networkId: "mainnet"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenWithMissingNetworkId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(tokenId: "bitcoin"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func tokenWithInvalidTokenId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .token,
            params: .init(tokenId: "bad token$", networkId: "mainnet"),
            deeplinkString: ""
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
            ),
            deeplinkString: ""
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
            ),
            deeplinkString: ""
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
            ),
            deeplinkString: ""
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
            ),
            deeplinkString: ""
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
            ),
            deeplinkString: ""
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
                params: .init(tokenId: "valid123", networkId: "net-456"),
                deeplinkString: ""
            )
            #expect(validator.hasMinimumDataForHandling(deeplink: action))
        }
    }

    @Test
    func optionalDestinations_withInvalidTokenId_shouldFail() {
        for destination in optionalDestinations {
            let action = DeeplinkNavigationAction(
                destination: destination,
                params: .init(tokenId: "🔥", networkId: "net"),
                deeplinkString: ""
            )
            #expect(!validator.hasMinimumDataForHandling(deeplink: action))
        }
    }

    @Test
    func optionalDestinations_withNoParams_shouldPass() {
        for destination in optionalDestinations {
            let action = DeeplinkNavigationAction(
                destination: destination,
                params: .empty,
                deeplinkString: ""
            )
            #expect(validator.hasMinimumDataForHandling(deeplink: action))
        }
    }

    // MARK: - Onboard Visa deeplink

    @Test
    func onboardVisaWithEntryAndId_shouldPass() {
        let action = DeeplinkNavigationAction(
            destination: .onboardVisa,
            params: .init(entry: "some-entry", id: "some-id"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func onboardVisaWithEntry_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .onboardVisa,
            params: .init(entry: "some-entry"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func onboardVisaWithId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .onboardVisa,
            params: .init(id: "some-id"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    // MARK: - News custom-scheme deeplink (tangem://news)

    @Test
    func newsWithNoParams_shouldPass() {
        let action = DeeplinkNavigationAction(
            destination: .news,
            params: .empty,
            deeplinkString: "tangem://news"
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func newsWithNumericCategoryId_shouldPass() {
        let action = DeeplinkNavigationAction(
            destination: .news,
            params: .init(categoryId: "12"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func newsWithNumericId_shouldPass() {
        let action = DeeplinkNavigationAction(
            destination: .news,
            params: .init(id: "900"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func newsWithNonNumericCategoryId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .news,
            params: .init(categoryId: "x"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func newsWithNonNumericArticleId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .news,
            params: .init(id: "x"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    // MARK: - News universal link (https://tangem.com/news/{category}/{id}-{slug})

    @Test
    func newsArticleWithNumericId_shouldPass() {
        let action = DeeplinkNavigationAction(
            destination: .newsArticle,
            params: .init(id: "190801"),
            deeplinkString: "https://tangem.com/news/markets/190801-polygon"
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func newsArticleWithNoParams_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .newsArticle,
            params: .empty,
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func newsArticleWithOnlyCategoryId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .newsArticle,
            params: .init(categoryId: "42"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func newsArticleWithEmptyId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .newsArticle,
            params: .init(id: ""),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func newsArticleWithNonNumericId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .newsArticle,
            params: .init(id: "abc"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func newsArticleWithInvalidCharactersInId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .newsArticle,
            params: .init(id: "190 801"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    // MARK: - Earn deeplink

    @Test
    func earnWithNoParams_shouldPass() {
        let action = DeeplinkNavigationAction(
            destination: .earn,
            params: .empty,
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func earnWithValidEarnTypeAndNetworkId_shouldPass() {
        let action = DeeplinkNavigationAction(
            destination: .earn,
            params: .init(networkId: "ethereum", earnType: "staking"),
            deeplinkString: ""
        )
        #expect(validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func earnWithInvalidEarnType_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .earn,
            params: .init(networkId: "ethereum", earnType: "bad$type"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }

    @Test
    func earnWithInvalidNetworkId_shouldFail() {
        let action = DeeplinkNavigationAction(
            destination: .earn,
            params: .init(networkId: "ethereum!", earnType: "yield"),
            deeplinkString: ""
        )
        #expect(!validator.hasMinimumDataForHandling(deeplink: action))
    }
}

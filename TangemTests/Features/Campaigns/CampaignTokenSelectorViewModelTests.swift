//
//  CampaignTokenSelectorViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemTestKit
import Testing
@testable import Tangem

@Suite("CampaignTokenSelectorViewModel", .tags(.campaigns), .serialized)
final class CampaignTokenSelectorViewModelTests: LeakTrackingTestSuite {
    private typealias Fixtures = PromotionCampaignsFixtures

    @Test("Add-token rows map the eligible backend token")
    func rowsMapEligibleBackendToken() async throws {
        try await withSelectedWallet {
            let sut = makeSUT(eligibleTokens: [Fixtures.makeToken()])

            let row = try #require(sut.eligibleTokenRows.first)
            #expect(sut.eligibleTokenRows.count == 1)
            #expect(row.name == "USD Coin")
            #expect(row.symbol == "USDC")
            #expect(row.tokenItem.contractAddress == "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
            #expect(row.tokenItem.networkId == "ethereum")
        }
    }

    @Test("Backend tokens without tokenId or decimals produce no add-token rows")
    func tokensWithoutIdOrDecimalsAreDropped() async {
        await withSelectedWallet {
            let sut = makeSUT(eligibleTokens: [
                Fixtures.makeToken(tokenId: nil),
                Fixtures.makeToken(decimals: nil),
            ])

            #expect(sut.eligibleTokenRows.isEmpty)
        }
    }

    @Test("Tokens already added to the wallet produce no add-token rows")
    func alreadyAddedTokensAreExcluded() async {
        await withSelectedWallet(userTokensManager: UserTokensManagerMock(containsTokenItem: true)) {
            let sut = makeSUT(eligibleTokens: [Fixtures.makeToken()])

            #expect(sut.eligibleTokenRows.isEmpty)
        }
    }

    @Test("Without a selected wallet there are no add-token rows")
    func noSelectedWalletProducesNoRows() async {
        await withInjectedCampaignDependencies(FakeTangemApiService(), userWalletRepository: FakeUserWalletRepository(models: [])) {
            let sut = makeSUT(eligibleTokens: [Fixtures.makeToken()])

            #expect(sut.eligibleTokenRows.isEmpty)
        }
    }

    @Test("Dismiss reports through the onClose callback")
    func dismissReportsThroughOnClose() async {
        await withSelectedWallet {
            var closeCallCount = 0
            let sut = makeSUT(eligibleTokens: [], onClose: { closeCallCount += 1 })

            sut.dismiss()

            #expect(closeCallCount == 1)
        }
    }

    @Test("Token selection forwards the item to the onSelect callback")
    func selectionForwardsToOnSelect() async {
        await withSelectedWallet {
            var selectedItems: [TokenSelectorItem] = []
            let sut = makeSUT(eligibleTokens: [], onSelect: { selectedItems.append($0) })
            let item = CampaignsFixtures.makeTokenSelectorItem()

            sut.userDidSelect(item: item)

            #expect(selectedItems.map(\.tokenItem) == [item.tokenItem])
        }
    }
}

// MARK: - Helpers

private extension CampaignTokenSelectorViewModelTests {
    func makeSUT(
        eligibleTokens: [BannerPromotion.Response.Token],
        onSelect: @escaping (TokenSelectorItem) -> Void = { _ in },
        onClose: @escaping () -> Void = {}
    ) -> CampaignTokenSelectorViewModel {
        trackForMemoryLeaks(
            CampaignTokenSelectorViewModel(
                eligibleTokens: eligibleTokens,
                initiallyExpandedAccount: nil,
                onSelect: onSelect,
                onClose: onClose
            )
        )
    }

    func withSelectedWallet(
        userTokensManager: UserTokensManager = UserTokensManagerMock(),
        operation: () async throws -> Void
    ) async rethrows {
        let wallet = CampaignUserWalletModelStub(
            walletIdSeed: "wallet-1",
            config: UserWalletConfigStub(supportedBlockchains: [.ethereum(testnet: false)]),
            userTokensManager: userTokensManager
        )
        let repository = FakeUserWalletRepository(models: [])
        repository.selectedModel = wallet

        try await withInjectedCampaignDependencies(FakeTangemApiService(), userWalletRepository: repository, operation: operation)
    }
}

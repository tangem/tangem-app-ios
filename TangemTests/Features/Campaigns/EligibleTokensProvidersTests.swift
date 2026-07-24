//
//  EligibleTokensProvidersTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
@testable import Tangem

@Suite("Eligible tokens providers", .tags(.campaigns))
struct EligibleTokensProvidersTests {
    private let eligibleItem = CampaignsFixtures.makeTokenSelectorItem()
    private let ineligibleItem = CampaignsFixtures.makeTokenSelectorItem(
        tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    )

    private var isEligible: (TokenItem) -> Bool {
        { $0.contractAddress != nil }
    }

    @Test("Items provider filters out ineligible tokens")
    func itemsProviderFiltersIneligibleTokens() async {
        let provider = EligibleTokensItemsProvider(
            base: ItemsProviderStub(items: [eligibleItem, ineligibleItem]),
            isEligible: isEligible
        )

        let items = await awaitEmissions(of: { provider.itemsPublisher }, where: { !$0.isEmpty })

        #expect(items?.last?.map(\.tokenItem) == [eligibleItem.tokenItem])
    }

    @Test("Wallets provider keeps the wallet structure and filters items in every account")
    func walletsProviderFiltersItemsInEveryAccount() async {
        let account = TokenSelectorAccount(
            account: CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in }),
            itemsProvider: ItemsProviderStub(items: [eligibleItem, ineligibleItem]),
            rateProvider: nil
        )
        let baseWallet = TokenSelectorWallet(wallet: eligibleItem.userWalletInfo, accounts: .multiple([account, account]))
        let provider = EligibleTokensWalletsProvider(
            base: WalletsProviderStub(wallets: [baseWallet]),
            isEligible: isEligible
        )

        let wallets = provider.wallets

        #expect(wallets.count == 1)
        guard case .multiple(let accounts) = wallets.first?.accounts else {
            Issue.record("Expected the multiple-accounts structure to be preserved")
            return
        }

        #expect(accounts.count == 2)

        for wrappedAccount in accounts {
            let items = await awaitEmissions(of: { wrappedAccount.itemsProvider.itemsPublisher }, where: { !$0.isEmpty })
            #expect(items?.last?.map(\.tokenItem) == [eligibleItem.tokenItem])
        }
    }

    @Test("Wallets provider preserves a single-account wallet")
    func walletsProviderPreservesSingleAccountWallet() {
        let account = TokenSelectorAccount(
            account: CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in }),
            itemsProvider: ItemsProviderStub(items: []),
            rateProvider: nil
        )
        let baseWallet = TokenSelectorWallet(wallet: eligibleItem.userWalletInfo, accounts: .single(account))
        let provider = EligibleTokensWalletsProvider(
            base: WalletsProviderStub(wallets: [baseWallet]),
            isEligible: isEligible
        )

        guard case .single = provider.wallets.first?.accounts else {
            Issue.record("Expected the single-account structure to be preserved")
            return
        }
    }
}

// MARK: - Stubs

private struct WalletsProviderStub: TokenSelectorWalletsProvider {
    let wallets: [TokenSelectorWallet]
}

private struct ItemsProviderStub: TokenSelectorAccountModelItemsProvider {
    let items: [TokenSelectorItem]

    var itemsPublisher: AnyPublisher<[TokenSelectorItem], Never> {
        Just(items).eraseToAnyPublisher()
    }
}

//
//  FilteredTokenSelectorWalletsProviderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
@testable import Tangem

@Suite("FilteredTokenSelectorWalletsProvider")
struct FilteredTokenSelectorWalletsProviderTests {
    private let includedItem = CampaignsFixtures.makeTokenSelectorItem()
    private let excludedItem = CampaignsFixtures.makeTokenSelectorItem(
        tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    )

    private var isIncluded: (TokenSelectorItem) -> Bool {
        { $0.tokenItem.contractAddress != nil }
    }

    @Test("Every account of a multi-account wallet gets its items filtered, structure preserved")
    func multiAccountWalletFiltersItemsInEveryAccount() async {
        let account = TokenSelectorAccount(
            account: CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in }),
            itemsProvider: ItemsProviderStub(items: [includedItem, excludedItem]),
            rateProvider: nil
        )
        let baseWallet = TokenSelectorWallet(wallet: includedItem.userWalletInfo, accounts: .multiple([account, account]))
        let provider = FilteredTokenSelectorWalletsProvider(
            base: WalletsProviderStub(wallets: [baseWallet]),
            isIncluded: isIncluded
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
            #expect(items?.last?.map(\.tokenItem) == [includedItem.tokenItem])
        }
    }

    @Test("A single-account wallet keeps its structure and gets its items filtered")
    func singleAccountWalletFiltersItems() async {
        let account = TokenSelectorAccount(
            account: CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in }),
            itemsProvider: ItemsProviderStub(items: [excludedItem, includedItem]),
            rateProvider: nil
        )
        let baseWallet = TokenSelectorWallet(wallet: includedItem.userWalletInfo, accounts: .single(account))
        let provider = FilteredTokenSelectorWalletsProvider(
            base: WalletsProviderStub(wallets: [baseWallet]),
            isIncluded: isIncluded
        )

        guard case .single(let wrappedAccount) = provider.wallets.first?.accounts else {
            Issue.record("Expected the single-account structure to be preserved")
            return
        }

        let items = await awaitEmissions(of: { wrappedAccount.itemsProvider.itemsPublisher }, where: { !$0.isEmpty })
        #expect(items?.last?.map(\.tokenItem) == [includedItem.tokenItem])
    }

    @Test("A wallet rejected by the wallet predicate disappears entirely")
    func rejectedWalletDisappears() {
        let account = TokenSelectorAccount(
            account: CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in }),
            itemsProvider: ItemsProviderStub(items: [includedItem]),
            rateProvider: nil
        )
        let baseWallet = TokenSelectorWallet(wallet: includedItem.userWalletInfo, accounts: .single(account))
        let provider = FilteredTokenSelectorWalletsProvider(
            base: WalletsProviderStub(wallets: [baseWallet]),
            includesWallet: { _ in false },
            isIncluded: { _ in true }
        )

        #expect(provider.wallets.isEmpty)
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

//
//  PolymarketSupportDataCollectorTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket support logs")
struct PolymarketSupportDataCollectorTests {
    @Test("The logs carry the Polymarket account the user asks about")
    func logsCarryTheAccount() throws {
        let accountModel = PolymarketAccountModelStub(
            state: .active,
            collateralTokenBalanceProvider: MutableTokenBalanceProviderMock(balance: Decimal(string: "12.5")!),
            collateralTotalBalanceProvider: MutableTokenBalanceProviderMock(balance: Decimal(string: "40.25")!)
        )

        let logs = try makeLogs(accountModel: accountModel, depositWalletAddressDerivation: .derived(address: depositWalletAddress))

        #expect(logs.contains("Polymarket account state: active\n"))
        #expect(logs.contains("Polymarket deposit wallet address: \(depositWalletAddress)\n"))
        #expect(logs.contains("Polymarket available balance: 12.5\n"))
        #expect(logs.contains("Polymarket total balance: 40.25\n"))
    }

    @Test("The account is read when the logs are sent, not when the chat was opened")
    func accountIsReadAtSendTime() throws {
        let availableBalance = MutableTokenBalanceProviderMock(initialState: .loading(nil))
        let accountModel = PolymarketAccountModelStub(state: nil, collateralTokenBalanceProvider: availableBalance)
        let collector = makeCollector(accountModel: accountModel, depositWalletAddressDerivation: .derived(address: depositWalletAddress))

        accountModel.state = .active
        availableBalance.balanceType = .failure(cachedBalance)

        let logs = try #require(collector.logData.flatMap { String(data: $0, encoding: .utf8) })

        #expect(logs.contains("Polymarket account state: active\n"))
        #expect(logs.contains("Polymarket available balance: failed, cached 7.5 at 1970-01-01T00:00:00Z\n"))
    }

    @Test("A failed balance reads differently from one still loading, and both keep the cached amount")
    func failedAndLoadingBalancesStayDistinct() throws {
        let accountModel = PolymarketAccountModelStub(
            state: .active,
            collateralTokenBalanceProvider: MutableTokenBalanceProviderMock(initialState: .failure(cachedBalance)),
            collateralTotalBalanceProvider: MutableTokenBalanceProviderMock(initialState: .loading(cachedBalance))
        )

        let logs = try makeLogs(accountModel: accountModel, depositWalletAddressDerivation: .derived(address: depositWalletAddress))

        #expect(logs.contains("Polymarket available balance: failed, cached 7.5 at 1970-01-01T00:00:00Z\n"))
        #expect(logs.contains("Polymarket total balance: loading, cached 7.5 at 1970-01-01T00:00:00Z\n"))
    }

    @Test("A wallet without a Polymarket account says so instead of listing empty balances")
    func missingAccountIsNamed() throws {
        let logs = try makeLogs(accountModel: nil, depositWalletAddressDerivation: .ownerAddressUnavailable)

        #expect(logs.contains("Polymarket account state: [no account]\n"))
        #expect(!logs.contains("Polymarket available balance"))
    }

    @Test("A missing owner key reads differently from an address that failed to derive")
    func depositAddressFailuresStayDistinct() throws {
        let missingOwner = try makeLogs(accountModel: nil, depositWalletAddressDerivation: .ownerAddressUnavailable)
        let failedDerivation = try makeLogs(accountModel: nil, depositWalletAddressDerivation: .derivationFailed(.invalidOwnerAddress))

        #expect(missingOwner.contains("Polymarket deposit wallet address: [owner address unavailable]\n"))
        #expect(failedDerivation.contains("Polymarket deposit wallet address: [derivation failed: invalidOwnerAddress]\n"))
    }

    @Test("The wallets follow the Polymarket account, split off by a separator")
    func walletsFollowTheAccount() throws {
        let collector = PolymarketSupportDataCollector(
            accountModel: PolymarketAccountModelStub(state: .active),
            depositWalletAddressDerivation: .derived(address: depositWalletAddress),
            walletsData: [DetailsFeedbackData(userWalletEmailData: [EmailCollectedData(type: .card(.cardId), data: cardId)], walletModels: [])]
        )

        let logs = try #require(collector.logData.flatMap { String(data: $0, encoding: .utf8) })

        #expect(logs.contains("Polymarket total balance: 0\n--------\nCard ID: \(cardId)\n"))
    }

    @Test("An account whose state has not arrived yet is told apart from a missing one")
    func notLoadedStateIsNamed() throws {
        let logs = try makeLogs(accountModel: PolymarketAccountModelStub(state: nil), depositWalletAddressDerivation: .derived(address: depositWalletAddress))

        #expect(logs.contains("Polymarket account state: [not loaded]\n"))
    }

    private var depositWalletAddress: String { "0xdf1a31b50D3F99d4460ACC1Bc99aB2e09BCcC538" }

    private var cardId: String { "CB79000000018201" }

    private var cachedBalance: TokenBalanceType.Cached {
        TokenBalanceType.Cached(balance: Decimal(string: "7.5")!, date: Date(timeIntervalSince1970: 0))
    }

    private func makeCollector(accountModel: PolymarketAccountModelStub?, depositWalletAddressDerivation: PolymarketSupportDataCollector.DepositWalletAddressDerivation) -> PolymarketSupportDataCollector {
        PolymarketSupportDataCollector(accountModel: accountModel, depositWalletAddressDerivation: depositWalletAddressDerivation, walletsData: [])
    }

    private func makeLogs(accountModel: PolymarketAccountModelStub?, depositWalletAddressDerivation: PolymarketSupportDataCollector.DepositWalletAddressDerivation) throws -> String {
        let collector = makeCollector(accountModel: accountModel, depositWalletAddressDerivation: depositWalletAddressDerivation)

        return try #require(collector.logData.flatMap { String(data: $0, encoding: .utf8) })
    }
}

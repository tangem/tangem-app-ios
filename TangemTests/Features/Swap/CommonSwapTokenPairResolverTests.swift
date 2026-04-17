//
//  CommonSwapTokenPairResolverTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import Testing
@testable import Tangem
@testable import BlockchainSdk
@testable import TangemStaking
import TangemTestKit

// MARK: - Suite

@Suite(.serialized)
class CommonSwapTokenPairResolverTests: LeakTrackingTestSuite {
    override init() {
        InjectedValues[\.expressAvailabilityProvider] = SwapTestAvailabilityProvider(canSwapTokens: [])
    }

    // MARK: - Scenario 1 + 6

    @Test("Scenario 1: exchangeable or non-exchangeable + has balance → FROM = current, TO = nil")
    func exchangeableWithBalance() {
        let currentToken = makeTokenItem(id: "eth")
        let walletModel = WalletModelTestsMock(tokenItem: currentToken, isEmpty: false, fiatBalance: 1)
        injectAvailability(canSwap: [currentToken])

        let resolver = makeSUT()
        let result = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        #expect(result.source?.tokenItem == currentToken)
        #expect(result.destination == nil)
    }

    // MARK: - Scenario 2

    @Test("Scenario 2: exchangeable + empty + account has exchangeable with balance → FROM = account token, TO = current")
    func exchangeableEmptyAccountHasExchangeableWithBalance() {
        let currentToken = makeTokenItem(id: "usdt")
        let accountToken = makeTokenItem(id: "eth")

        let accountWM = WalletModelTestsMock(tokenItem: accountToken, isEmpty: false, fiatBalance: 500)
        let walletModel = makeWalletModelWithAccount(
            tokenItem: currentToken,
            isEmpty: true,
            accountWalletModels: [accountWM]
        )
        injectAvailability(canSwap: [currentToken, accountToken])

        let resolver = makeSUT()
        let result = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        #expect(result.source?.tokenItem == accountToken)
        #expect(result.destination?.tokenItem == currentToken)
    }

    // MARK: - Scenario 3

    @Test("Scenario 3: exchangeable + empty + account has exchangeable without balance → FROM = nil, TO = current")
    func exchangeableEmptyAccountHasExchangeableEmpty() {
        let currentToken = makeTokenItem(id: "usdt")
        let accountToken = makeTokenItem(id: "eth")

        let accountWM = WalletModelTestsMock(tokenItem: accountToken, isEmpty: true)
        let walletModel = makeWalletModelWithAccount(
            tokenItem: currentToken,
            isEmpty: true,
            accountWalletModels: [accountWM]
        )
        injectAvailability(canSwap: [currentToken, accountToken])

        let resolver = makeSUT()
        let result = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        #expect(result.source == nil)
        #expect(result.destination?.tokenItem == currentToken)
    }

    // MARK: - Scenario 4

    @Test("Scenario 4: exchangeable + empty + no exchangeable in account, no balance → FROM = nil, TO = current")
    func exchangeableEmptyAccountEmpty() {
        let currentToken = makeTokenItem(id: "usdt")

        let walletModel = makeWalletModelWithAccount(
            tokenItem: currentToken,
            isEmpty: true,
            accountWalletModels: []
        )
        injectAvailability(canSwap: [currentToken])

        let resolver = makeSUT()
        let result = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        #expect(result.source == nil)
        #expect(result.destination?.tokenItem == currentToken)
    }

    // MARK: - Scenario 5

    @Test("Scenario 5: exchangeable + empty + no exchangeable, has non-exchangeable with balance → FROM = most funded, TO = current")
    func exchangeableEmptyAccountHasNonExchangeableWithBalance() {
        let currentToken = makeTokenItem(id: "usdt")
        let nonExchangeableToken = makeTokenItem(id: "rare")

        let nonExchangeableWM = WalletModelTestsMock(tokenItem: nonExchangeableToken, isEmpty: false, fiatBalance: 200)
        let walletModel = makeWalletModelWithAccount(
            tokenItem: currentToken,
            isEmpty: true,
            accountWalletModels: [nonExchangeableWM]
        )
        injectAvailability(canSwap: [currentToken])

        let resolver = makeSUT()
        let result = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        #expect(result.source?.tokenItem == nonExchangeableToken)
        #expect(result.destination?.tokenItem == currentToken)
    }

    // MARK: - Scenario 7a

    @Test("Scenario 7a: non-exchangeable + empty + account has funded token → FROM = most funded, TO = current")
    func nonExchangeableEmptyAccountHasFunded() {
        let currentToken = makeTokenItem(id: "rare")
        let fundedToken = makeTokenItem(id: "eth")

        let fundedWM = WalletModelTestsMock(tokenItem: fundedToken, isEmpty: false, fiatBalance: 300)
        let walletModel = makeWalletModelWithAccount(
            tokenItem: currentToken,
            isEmpty: true,
            accountWalletModels: [fundedWM]
        )
        injectAvailability(canSwap: [])

        let resolver = makeSUT()
        let result = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        #expect(result.source?.tokenItem == fundedToken)
        #expect(result.destination?.tokenItem == currentToken)
    }

    // MARK: - Scenario 7b

    @Test("Scenario 7b: non-exchangeable + empty + account all empty → FROM = nil, TO = current")
    func nonExchangeableEmptyAccountAllEmpty() {
        let currentToken = makeTokenItem(id: "rare")

        let walletModel = makeWalletModelWithAccount(
            tokenItem: currentToken,
            isEmpty: true,
            accountWalletModels: []
        )
        injectAvailability(canSwap: [])

        let resolver = makeSUT()
        let result = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        #expect(result.source == nil)
        #expect(result.destination?.tokenItem == currentToken)
    }

    // MARK: - Scenario 4 (with non-empty account)

    @Test("Scenario 4: exchangeable + empty + account has only non-exchangeable empty tokens → FROM = first in account, TO = current")
    func exchangeableEmptyAccountHasOnlyEmptyNonExchangeable() {
        let currentToken = makeTokenItem(id: "usdt")
        let emptyNonExchangeable = makeTokenItem(id: "rare")

        let emptyWM = WalletModelTestsMock(tokenItem: emptyNonExchangeable, isEmpty: true)
        let walletModel = makeWalletModelWithAccount(
            tokenItem: currentToken,
            isEmpty: true,
            accountWalletModels: [emptyWM]
        )
        injectAvailability(canSwap: [currentToken])

        let resolver = makeSUT()
        let result = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        #expect(result.source?.tokenItem == emptyNonExchangeable)
        #expect(result.destination?.tokenItem == currentToken)
    }

    // MARK: - Scenario 7b (with non-empty account)

    @Test("Scenario 7b: non-exchangeable + empty + account has only empty tokens → FROM = first in account, TO = current")
    func nonExchangeableEmptyAccountHasOnlyEmptyTokens() {
        let currentToken = makeTokenItem(id: "rare")
        let otherEmpty = makeTokenItem(id: "other")

        let otherWM = WalletModelTestsMock(tokenItem: otherEmpty, isEmpty: true)
        let walletModel = makeWalletModelWithAccount(
            tokenItem: currentToken,
            isEmpty: true,
            accountWalletModels: [otherWM]
        )
        injectAvailability(canSwap: [])

        let resolver = makeSUT()
        let result = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        #expect(result.source?.tokenItem == otherEmpty)
        #expect(result.destination?.tokenItem == currentToken)
    }

    // MARK: - Scenario 2 (multiple competing tokens)

    @Test("Scenario 2: multiple exchangeable tokens with balance → picks highest fiat balance")
    func exchangeableEmptyAccountPicksHighestBalance() {
        let currentToken = makeTokenItem(id: "usdt")
        let lowToken = makeTokenItem(id: "dai")
        let highToken = makeTokenItem(id: "eth")

        let lowWM = WalletModelTestsMock(tokenItem: lowToken, isEmpty: false, fiatBalance: 100)
        let highWM = WalletModelTestsMock(tokenItem: highToken, isEmpty: false, fiatBalance: 500)
        let walletModel = makeWalletModelWithAccount(
            tokenItem: currentToken,
            isEmpty: true,
            accountWalletModels: [lowWM, highWM]
        )
        injectAvailability(canSwap: [currentToken, lowToken, highToken])

        let resolver = makeSUT()
        let result = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        #expect(result.source?.tokenItem == highToken)
        #expect(result.destination?.tokenItem == currentToken)
    }
}

// MARK: - Helpers

private extension CommonSwapTokenPairResolverTests {
    func makeSUT() -> CommonSwapTokenPairResolver {
        trackForMemoryLeaks(CommonSwapTokenPairResolver())
    }

    func makeTokenItem(id: String) -> TokenItem {
        let token = Token(name: id, symbol: id.uppercased(), contractAddress: id, decimalCount: 18)
        return .token(token, .init(.ethereum(testnet: false), derivationPath: nil))
    }

    func makeWalletModelWithAccount(
        tokenItem: TokenItem,
        isEmpty: Bool,
        accountWalletModels: [any WalletModel]
    ) -> WalletModelTestsMock {
        let walletModelsManager = WalletModelsManagerTestsMock()
        let account = CryptoAccountModelMock(
            isMainAccount: true,
            walletModelsManager: walletModelsManager,
            onArchive: { _ in }
        )
        let walletModel = WalletModelTestsMock(tokenItem: tokenItem, isEmpty: isEmpty, account: account)
        walletModelsManager.walletModels = [walletModel] + accountWalletModels
        return walletModel
    }

    func injectAvailability(canSwap tokens: [TokenItem]) {
        InjectedValues[\.expressAvailabilityProvider] = SwapTestAvailabilityProvider(canSwapTokens: Set(tokens))
    }
}

// MARK: - Mock ExpressAvailabilityProvider

private final class SwapTestAvailabilityProvider: ExpressAvailabilityProvider {
    private let canSwapTokens: Set<TokenItem>

    init(canSwapTokens: Set<TokenItem>) {
        self.canSwapTokens = canSwapTokens
    }

    var hasCache: Bool { true }
    var availabilityDidChangePublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
    var expressAvailabilityUpdateStateValue: ExpressAvailabilityUpdateState { .updated }
    var expressAvailabilityUpdateState: AnyPublisher<ExpressAvailabilityUpdateState, Never> { .just(output: .updated) }

    func swapState(for tokenItem: TokenItem) -> TokenItemExpressState { canSwapTokens.contains(tokenItem) ? .available : .unavailable }
    func onrampState(for tokenItem: TokenItem) -> TokenItemExpressState { .unavailable }
    func canSwap(tokenItem: TokenItem) -> Bool { canSwapTokens.contains(tokenItem) }
    func canOnramp(tokenItem: TokenItem) -> Bool { false }
    func updateExpressAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String) {}
}

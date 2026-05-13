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

    // MARK: - Main Screen: Scenario 1/3 (has balance)

    @Test("Main screen: token with balance → FROM = most funded in wallet, TO = nil")
    func mainScreen_hasBalance_picksMostFunded() {
        let token1 = makeTokenItem(id: "eth")
        let token2 = makeTokenItem(id: "btc")
        let wm1 = WalletModelTestsMock(tokenItem: token1, isEmpty: false, fiatBalance: 100)
        let wm2 = WalletModelTestsMock(tokenItem: token2, isEmpty: false, fiatBalance: 500)

        let resolver = makeSUT()
        let result = resolver.resolve(for: .mainScreen(.init(orderedWalletModels: [wm1, wm2])))

        #expect(result.source?.tokenItem == token2)
        #expect(result.destination == nil)
    }

    @Test("Main screen: most funded token is in second account → still picks it (wallet-wide)")
    func mainScreen_crossAccount_picksMostFundedFromSecondAccount() {
        let token1 = makeTokenItem(id: "eth")
        let token2 = makeTokenItem(id: "btc")
        let wm1 = WalletModelTestsMock(tokenItem: token1, isEmpty: false, fiatBalance: 100)
        let wm2 = WalletModelTestsMock(tokenItem: token2, isEmpty: false, fiatBalance: 500)

        let resolver = makeSUT()
        let result = resolver.resolve(for: .mainScreen(.init(orderedWalletModels: [wm1, wm2])))

        #expect(result.source?.tokenItem == token2)
        #expect(result.destination == nil)
    }

    // MARK: - Main Screen: Scenario 2/4 (no balance, tokens exist)

    @Test("Main screen: no balance, tokens exist → FROM = first token of first account in UI order, TO = nil")
    func mainScreen_noBalance_picksFirstOfFirstAccount() {
        let topToken = makeTokenItem(id: "eth")
        let bottomToken = makeTokenItem(id: "btc")
        let topWM = WalletModelTestsMock(tokenItem: topToken, isEmpty: true)
        let bottomWM = WalletModelTestsMock(tokenItem: bottomToken, isEmpty: true)

        // Input array order = UI order (top → bottom), captured via TokenSectionsAdapter snapshot.
        let resolver = makeSUT()
        let result = resolver.resolve(for: .mainScreen(.init(orderedWalletModels: [topWM, bottomWM])))

        #expect(result.source?.tokenItem == topToken)
        #expect(result.destination == nil)
    }

    @Test("Main screen: no balance, multiple accounts → FROM = first token of FIRST account, not second")
    func mainScreen_noBalance_multipleAccounts_picksFirstOfFirstAccount() {
        let firstAccountToken = makeTokenItem(id: "eth")
        let secondAccountToken = makeTokenItem(id: "btc")
        let wm1 = WalletModelTestsMock(tokenItem: firstAccountToken, isEmpty: true)
        let wm2 = WalletModelTestsMock(tokenItem: secondAccountToken, isEmpty: true)

        let resolver = makeSUT()
        let result = resolver.resolve(for: .mainScreen(.init(orderedWalletModels: [wm1, wm2])))

        #expect(result.source?.tokenItem == firstAccountToken)
        #expect(result.destination == nil)
    }

    // MARK: - Main Screen: Scenario 5 (no tokens)

    @Test("Main screen: no tokens at all → FROM = nil, TO = nil")
    func mainScreen_noTokens_bothNil() {
        let resolver = makeSUT()
        let result = resolver.resolve(for: .mainScreen(.init(orderedWalletModels: [])))

        #expect(result.source == nil)
        #expect(result.destination == nil)
    }

    @Test("Main screen: snapshot already excludes TangemPay accounts — only crypto wallet models are passed")
    func mainScreen_tangemPayAccount_ignored() {
        let cryptoToken = makeTokenItem(id: "eth")
        let cryptoWM = WalletModelTestsMock(tokenItem: cryptoToken, isEmpty: false, fiatBalance: 100)

        let resolver = makeSUT()
        // The call site (sections provider) is responsible for filtering out TangemPay before passing.
        // Resolver works on the snapshot it gets — verify it picks the crypto token correctly.
        let result = resolver.resolve(for: .mainScreen(.init(orderedWalletModels: [cryptoWM])))

        #expect(result.source?.tokenItem == cryptoToken)
        #expect(result.destination == nil)
    }

    @Test("Main screen: accounts exist but empty (no wallet models) → FROM = nil, TO = nil")
    func mainScreen_emptyAccounts_bothNil() {
        let resolver = makeSUT()
        let result = resolver.resolve(for: .mainScreen(.init(orderedWalletModels: [])))

        #expect(result.source == nil)
        #expect(result.destination == nil)
    }

    // MARK: - Availability guard: open token itself not available

    @Test("Token details: open token not available for swap → FROM = nil, TO = nil")
    func tokenDetails_targetUnavailable_returnsBothNil() {
        let currentToken = makeTokenItem(id: "custom")
        let walletModel = WalletModelTestsMock(tokenItem: currentToken, isEmpty: false, fiatBalance: 100)

        let mock = SwapAvailabilityCheckerMock()
        mock.unavailableIds = [walletModel.id]

        let resolver = makeSUT(swapAvailabilityChecker: mock)
        let result = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        #expect(result.source == nil)
        #expect(result.destination == nil)
    }

    @Test("Markets: open token not available for swap → FROM = nil, TO = nil")
    func markets_targetUnavailable_returnsBothNil() {
        let currentToken = makeTokenItem(id: "custom")
        let walletModel = WalletModelTestsMock(tokenItem: currentToken, isEmpty: false, fiatBalance: 100)

        let mock = SwapAvailabilityCheckerMock()
        mock.unavailableIds = [walletModel.id]

        let resolver = makeSUT(swapAvailabilityChecker: mock)
        let result = resolver.resolve(for: .markets(.init(walletModel: walletModel)))

        #expect(result.source == nil)
        #expect(result.destination == nil)
    }

    // MARK: - Markets origin: basic resolution

    @Test("Markets: open token with balance → FROM = current, TO = nil (mirrors tokenDetails scenario 1)")
    func markets_openTokenWithBalance_picksCurrent() {
        let currentToken = makeTokenItem(id: "eth")
        let walletModel = WalletModelTestsMock(tokenItem: currentToken, isEmpty: false, fiatBalance: 1)
        injectAvailability(canSwap: [currentToken])

        let resolver = makeSUT()
        let result = resolver.resolve(for: .markets(.init(walletModel: walletModel)))

        #expect(result.source?.tokenItem == currentToken)
        #expect(result.destination == nil)
    }

    // MARK: - Availability filter: other tokens in account

    @Test("Token details: other token in account not available for swap → filtered out from FROM pool")
    func tokenDetails_siblingUnavailable_filteredFromPool() {
        let currentToken = makeTokenItem(id: "usdt")
        let otherToken = makeTokenItem(id: "custom")

        let otherWM = WalletModelTestsMock(tokenItem: otherToken, isEmpty: false, fiatBalance: 500)
        let walletModel = makeWalletModelWithAccount(
            tokenItem: currentToken,
            isEmpty: true,
            accountWalletModels: [otherWM]
        )
        injectAvailability(canSwap: [currentToken])

        let mock = SwapAvailabilityCheckerMock()
        mock.unavailableIds = [otherWM.id]

        let resolver = makeSUT(swapAvailabilityChecker: mock)
        let result = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        // Other token filtered out → no candidates for FROM
        #expect(result.source == nil)
        #expect(result.destination?.tokenItem == currentToken)
    }

    // MARK: - Main screen: isSwapAvailable filter

    @Test("Main screen: all tokens unavailable for swap, some have funds → FROM = nil (filtered out)")
    func mainScreen_noAvailableHasFunded_returnsNil() {
        let token1 = makeTokenItem(id: "custom1")
        let token2 = makeTokenItem(id: "custom2")
        let wm1 = WalletModelTestsMock(tokenItem: token1, isEmpty: false, fiatBalance: 100)
        let wm2 = WalletModelTestsMock(tokenItem: token2, isEmpty: false, fiatBalance: 500)

        let mock = SwapAvailabilityCheckerMock()
        mock.unavailableIds = [wm1.id, wm2.id]

        let resolver = makeSUT(swapAvailabilityChecker: mock)
        let result = resolver.resolve(for: .mainScreen(.init(orderedWalletModels: [wm1, wm2])))

        #expect(result.source == nil)
        #expect(result.destination == nil)
    }

    @Test("Main screen: all tokens unavailable for swap, all empty → FROM = nil (filtered out)")
    func mainScreen_noAvailableAllEmpty_returnsNil() {
        let token1 = makeTokenItem(id: "custom1")
        let token2 = makeTokenItem(id: "custom2")
        let wm1 = WalletModelTestsMock(tokenItem: token1, isEmpty: true)
        let wm2 = WalletModelTestsMock(tokenItem: token2, isEmpty: true)

        let mock = SwapAvailabilityCheckerMock()
        mock.unavailableIds = [wm1.id, wm2.id]

        let resolver = makeSUT(swapAvailabilityChecker: mock)
        let result = resolver.resolve(for: .mainScreen(.init(orderedWalletModels: [wm1, wm2])))

        #expect(result.source == nil)
        #expect(result.destination == nil)
    }

    // MARK: - Main screen: first account empty, second has tokens

    @Test("Main screen: first account has no tokens, second has funded → FROM from second account")
    func mainScreen_firstAccountEmptyButSecondFunded_picksFromSecond() {
        let token2 = makeTokenItem(id: "eth")
        let wm2 = WalletModelTestsMock(tokenItem: token2, isEmpty: false, fiatBalance: 500)

        let resolver = makeSUT()
        let result = resolver.resolve(for: .mainScreen(.init(orderedWalletModels: [wm2])))

        // mostFundedInWallet aggregates across accounts → picks wm2 from second account
        #expect(result.source?.tokenItem == token2)
        #expect(result.destination == nil)
    }

    // MARK: - Main screen: snapshot drives iteration order

    @Test("Main screen: snapshot dictates iteration → FROM = first element regardless of any other ordering")
    func mainScreen_snapshotDrivesOrder_picksFirstElement() {
        let firstUI = makeTokenItem(id: "eth")
        let secondUI = makeTokenItem(id: "btc")
        let thirdUI = makeTokenItem(id: "sol")
        let firstWM = WalletModelTestsMock(tokenItem: firstUI, isEmpty: true)
        let secondWM = WalletModelTestsMock(tokenItem: secondUI, isEmpty: true)
        let thirdWM = WalletModelTestsMock(tokenItem: thirdUI, isEmpty: true)

        // Snapshot is what the user sees after grouping/sorting/drag-and-drop. Resolver
        // iterates this array directly — there's no internal reordering anymore.
        let resolver = makeSUT()
        let result = resolver.resolve(
            for: .mainScreen(.init(orderedWalletModels: [firstWM, secondWM, thirdWM]))
        )

        #expect(result.source?.tokenItem == firstUI)
        #expect(result.destination == nil)
    }

    @Test("Main screen: equal balances → FROM = first iterated wins the tie")
    func mainScreen_equalBalances_picksFirstIteratedTie() {
        let topToken = makeTokenItem(id: "eth")
        let bottomToken = makeTokenItem(id: "btc")
        let topWM = WalletModelTestsMock(tokenItem: topToken, isEmpty: false, fiatBalance: 100)
        let bottomWM = WalletModelTestsMock(tokenItem: bottomToken, isEmpty: false, fiatBalance: 100)

        // Strict `>` comparison means whoever is iterated first wins the tie.
        let resolver = makeSUT()
        let result = resolver.resolve(
            for: .mainScreen(.init(orderedWalletModels: [topWM, bottomWM]))
        )

        #expect(result.source?.tokenItem == topToken)
        #expect(result.destination == nil)
    }

    @Test("Main screen: first account empty, second has only unavailable+empty tokens → FROM = nil (filtered out)")
    func mainScreen_firstAccountEmptySecondOnlyUnavailableEmpty_returnsNil() {
        let token2 = makeTokenItem(id: "custom2")
        let wm2 = WalletModelTestsMock(tokenItem: token2, isEmpty: true)

        let mock = SwapAvailabilityCheckerMock()
        mock.unavailableIds = [wm2.id]

        let resolver = makeSUT(swapAvailabilityChecker: mock)
        let result = resolver.resolve(for: .mainScreen(.init(orderedWalletModels: [wm2])))

        #expect(result.source == nil)
        #expect(result.destination == nil)
    }

    // MARK: - Exchangeable priority over balance

    @Test("Token details: exchangeable ($100) + non-exchangeable ($500) → exchangeable wins (type priority over balance)")
    func tokenDetails_exchangeableAndNonExchangeableMixed_exchangeableWins() {
        let currentToken = makeTokenItem(id: "usdt")
        let exchangeableToken = makeTokenItem(id: "eth")
        let nonExchangeableToken = makeTokenItem(id: "rare")

        let exchangeableWM = WalletModelTestsMock(tokenItem: exchangeableToken, isEmpty: false, fiatBalance: 100)
        let nonExchangeableWM = WalletModelTestsMock(tokenItem: nonExchangeableToken, isEmpty: false, fiatBalance: 500)

        let walletModel = makeWalletModelWithAccount(
            tokenItem: currentToken,
            isEmpty: true,
            accountWalletModels: [exchangeableWM, nonExchangeableWM]
        )
        // Only currentToken and exchangeableToken are swappable via Express
        injectAvailability(canSwap: [currentToken, exchangeableToken])

        let resolver = makeSUT()
        let result = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        // Exchangeable wins despite lower balance (topExchangeable branch wins)
        #expect(result.source?.tokenItem == exchangeableToken)
        #expect(result.destination?.tokenItem == currentToken)
    }

    // MARK: - Nice-to-have

    @Test("Main screen: snapshot already excludes TangemPay accounts, no crypto wallet models → FROM = nil, TO = nil")
    func mainScreen_onlyTangemPay_returnsBothNil() {
        // The snapshot provider is responsible for filtering out TangemPay before passing to the resolver.
        // From the resolver's perspective this is indistinguishable from "no accounts at all".
        let resolver = makeSUT()
        let result = resolver.resolve(for: .mainScreen(.init(orderedWalletModels: [])))

        #expect(result.source == nil)
        #expect(result.destination == nil)
    }

    @Test("Token details: two tokens with equal balance → first encountered wins (stable ordering)")
    func tokenDetails_equalBalances_firstEncounteredWins() {
        let currentToken = makeTokenItem(id: "usdt")
        let firstToken = makeTokenItem(id: "eth")
        let secondToken = makeTokenItem(id: "btc")

        let firstWM = WalletModelTestsMock(tokenItem: firstToken, isEmpty: false, fiatBalance: 100)
        let secondWM = WalletModelTestsMock(tokenItem: secondToken, isEmpty: false, fiatBalance: 100)

        let walletModel = makeWalletModelWithAccount(
            tokenItem: currentToken,
            isEmpty: true,
            accountWalletModels: [firstWM, secondWM]
        )
        injectAvailability(canSwap: [currentToken, firstToken, secondToken])

        let resolver = makeSUT()
        let result = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        // On equal balances, first iterated (firstWM) wins because `fiat > mostFundedFiat` is false for second
        #expect(result.source?.tokenItem == firstToken)
        #expect(result.destination?.tokenItem == currentToken)
    }
}

// MARK: - Helpers

private extension CommonSwapTokenPairResolverTests {
    func makeSUT(swapAvailabilityChecker: some SwapAvailabilityChecker = SwapAvailabilityCheckerMock()) -> CommonSwapTokenPairResolver {
        trackForMemoryLeaks(CommonSwapTokenPairResolver(swapAvailabilityChecker: swapAvailabilityChecker))
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

// MARK: - Mock SwapAvailabilityChecker

private final class SwapAvailabilityCheckerMock: SwapAvailabilityChecker {
    var unavailableIds: Set<WalletModelId> = []

    func isSwapAvailable(walletModel: any WalletModel) -> Bool {
        !unavailableIds.contains(walletModel.id)
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

// MARK: - Mock UserTokensManager

private final class UserTokensManagerTestsMock: UserTokensManager {
    let userTokens: [TokenItem]

    init(userTokens: [TokenItem]) {
        self.userTokens = userTokens
    }

    var userTokensPublisher: AnyPublisher<[TokenItem], Never> { .just(output: userTokens) }
    var derivationManager: (DerivationManager & DerivationStatusProvider)? { nil }

    func deriveIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) { completion(.success(())) }
    func contains(_ tokenItem: TokenItem, derivationInsensitive: Bool) -> Bool { false }
    func needsCardDerivation(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) -> Bool { false }
    func update(
        itemsToRemove: [TokenItem],
        itemsToAdd: [TokenItem],
        completion: @escaping (Result<UserTokensManagerResult.UpdatedTokenItems, any Error>) -> Void
    ) {
        completion(.success(.init(removed: itemsToRemove, added: itemsToAdd)))
    }

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) throws {}
    func addTokenItemHardwarePrecondition(_ tokenItem: TokenItem) throws {}
    func addTokenItemPrecondition(_ tokenItem: TokenItem) throws {}
    func add(_ tokenItem: TokenItem) async throws -> String { "" }
    func add(_ tokenItems: [TokenItem], completion: @escaping (Result<[TokenItem], Error>) -> Void) { completion(.success(tokenItems)) }
    func canRemove(_ tokenItem: TokenItem, pendingToAddItems: [TokenItem], pendingToRemoveItems: [TokenItem]) -> Bool { false }
    func remove(_ tokenItem: TokenItem) {}
    func sync(completion: @escaping () -> Void) { completion() }
}

// MARK: - UserTokensReordering protocol conformance

extension UserTokensManagerTestsMock: UserTokensReordering {
    var orderedWalletModelIds: AnyPublisher<[WalletModelId.ID], Never> { .just(output: []) }
    var groupingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> { .just(output: .none) }
    var sortingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> { .just(output: .dragAndDrop) }
    func reorder(_ actions: [UserTokensReorderingAction], source: UserTokensReorderingSource) -> AnyPublisher<Void, Never> { .just }
}

// MARK: - DisposableEntity protocol conformance

extension UserTokensManagerTestsMock: DisposableEntity {
    func dispose() {}
}

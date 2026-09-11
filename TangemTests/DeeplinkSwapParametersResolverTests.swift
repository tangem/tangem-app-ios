//
//  DeeplinkSwapParametersResolverTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("DeeplinkSwapParametersResolver selection")
struct DeeplinkSwapParametersResolverTests {
    typealias Candidate = DeeplinkSwapParametersResolver.Candidate

    private let walletId = "wallet-1"

    // MARK: - Case 1: nothing → Main

    @Test("Empty deeplink → nil (open swap as from Main)")
    func emptyDeeplink() {
        let result = select(candidates: [candidate(index: 0, token: "ethereum", network: "ethereum", balance: 100)], params: params())
        #expect(result == nil)
    }

    // MARK: - Case 2: incomplete FROM → Main

    @Test("from_token_id without network → nil")
    func fromWithoutNetwork() {
        let result = select(
            candidates: [candidate(index: 0, token: "ethereum", network: "ethereum", balance: 100)],
            params: params(fromToken: "ethereum")
        )
        #expect(result == nil)
    }

    // MARK: - Case 3: both held

    @Test("FROM picks the most-funded matching token across accounts")
    func fromMostFunded() {
        let candidates = [
            candidate(index: 0, token: "ethereum", network: "ethereum", account: 0, balance: 10),
            candidate(index: 1, token: "ethereum", network: "ethereum", account: 1, balance: 50),
        ]
        let result = select(candidates: candidates, params: params(fromToken: "ethereum", fromNetwork: "ethereum"))
        #expect(result?.source == candidates[1])
        #expect(result?.destination == nil)
    }

    @Test("TO prefers the same account as the resolved FROM over a more-funded other account")
    func toPrefersFromAccount() {
        let candidates = [
            candidate(index: 0, token: "ethereum", network: "ethereum", account: 3, balance: 100), // FROM (most funded)
            candidate(index: 1, token: "usd-coin", network: "ethereum", account: 3, balance: 5), // TO in FROM's account
            candidate(index: 2, token: "usd-coin", network: "ethereum", account: 7, balance: 999), // richer TO elsewhere
        ]
        let result = select(
            candidates: candidates,
            params: params(fromToken: "ethereum", fromNetwork: "ethereum", toToken: "usd-coin", toNetwork: "ethereum")
        )
        #expect(result?.source == candidates[0])
        #expect(result?.destination == candidates[1])
        #expect(result?.appliesExtras == true) // full explicit held pair → amount/provider apply
    }

    @Test("TO falls back to the most-funded other account when FROM's account lacks it")
    func toMostFundedOtherAccount() {
        let candidates = [
            candidate(index: 0, token: "ethereum", network: "ethereum", account: 3, balance: 100), // FROM
            candidate(index: 1, token: "usd-coin", network: "ethereum", account: 7, balance: 5),
            candidate(index: 2, token: "usd-coin", network: "ethereum", account: 9, balance: 40),
        ]
        let result = select(
            candidates: candidates,
            params: params(fromToken: "ethereum", fromNetwork: "ethereum", toToken: "usd-coin", toNetwork: "ethereum")
        )
        #expect(result?.source == candidates[0])
        #expect(result?.destination == candidates[2])
    }

    // MARK: - Case 4: token(s) not held

    @Test("FROM not held, TO held → best-effort source + TO preselected")
    func fromNotHeldToHeld() {
        let candidates = [
            candidate(index: 0, token: "bitcoin", network: "bitcoin", balance: 70, swappable: true), // best-effort source
            candidate(index: 1, token: "solana", network: "solana", balance: 5),
        ]
        let result = select(
            candidates: candidates,
            params: params(fromToken: "ethereum", fromNetwork: "ethereum", toToken: "solana", toNetwork: "solana")
        )
        #expect(result?.source == candidates[0])
        #expect(result?.destination == candidates[1])
        #expect(result?.appliesExtras == false) // FROM is best-effort, not the requested token → no amount/provider
    }

    @Test("FROM held, TO not held → FROM preselected, TO left empty")
    func fromHeldToNotHeld() {
        let candidates = [candidate(index: 0, token: "ethereum", network: "ethereum", balance: 10)]
        let result = select(
            candidates: candidates,
            params: params(fromToken: "ethereum", fromNetwork: "ethereum", toToken: "solana", toNetwork: "solana")
        )
        #expect(result?.source == candidates[0])
        #expect(result?.destination == nil)
        #expect(result?.appliesExtras == false) // TO not held → incomplete pair → no amount/provider
    }

    @Test("Neither FROM nor TO held → nil (open swap as from Main)")
    func neitherHeld() {
        let candidates = [candidate(index: 0, token: "bitcoin", network: "bitcoin", balance: 10)]
        let result = select(
            candidates: candidates,
            params: params(fromToken: "ethereum", fromNetwork: "ethereum", toToken: "solana", toNetwork: "solana")
        )
        #expect(result == nil)
    }

    // MARK: - Case 5: inconsistent per-side wallet / account

    @Test("from_user_wallet_id targeting a different wallet → FROM treated as not requested")
    func fromWalletMismatchFallsBack() {
        let candidates = [
            candidate(index: 0, token: "ethereum", network: "ethereum", balance: 10),
            candidate(index: 1, token: "solana", network: "solana", balance: 5),
        ]
        // FROM points at another wallet → ignored; TO still preselected, FROM = best-effort.
        let result = select(
            candidates: candidates,
            params: params(
                fromToken: "ethereum",
                fromNetwork: "ethereum",
                toToken: "solana",
                toNetwork: "solana",
                fromWalletId: "other-wallet"
            )
        )
        #expect(result?.source == candidates[0]) // best-effort most-funded
        #expect(result?.destination == candidates[1])
    }

    @Test("from_user_account_id not present in the wallet → ignored, FROM still preselected")
    func fromAccountMissingIsIgnored() {
        let candidates = [candidate(index: 0, token: "ethereum", network: "ethereum", balance: 10)]
        let result = select(
            candidates: candidates,
            params: params(fromToken: "ethereum", fromNetwork: "ethereum", fromAccountId: "does-not-exist"),
            existingAccounts: ["real-account": 0]
        )
        // The unknown account narrows nothing; the requested token is still honored.
        #expect(result?.source == candidates[0])
    }

    /// [REDACTED_INFO]: an unrecognized account id shared by both sides used to discard the whole pair,
    /// leaving the swap screen to auto-pick FROM/TO by balance.
    @Test("Unknown account id on both sides → pair and extras still resolved from the token ids")
    func unknownAccountIdOnBothSidesKeepsPair() {
        let candidates = [
            candidate(index: 0, token: "ethereum", network: "ethereum", account: 0, balance: 3),
            candidate(index: 1, token: "usd-coin", network: "ethereum", account: 0, balance: 1),
            candidate(index: 2, token: "solana", network: "solana", account: 0, balance: 100), // richest, must not win
        ]
        let result = select(
            candidates: candidates,
            params: params(
                fromToken: "ethereum",
                fromNetwork: "ethereum",
                toToken: "usd-coin",
                toNetwork: "ethereum",
                fromAccountId: "not-on-this-device",
                toAccountId: "not-on-this-device"
            ),
            existingAccounts: ["real-account": 0]
        )

        #expect(result?.source == candidates[0])
        #expect(result?.destination == candidates[1])
        #expect(result?.appliesExtras == true) // the amount from the link applies to a fully matched pair
    }

    /// [REDACTED_INFO]: a corrupted `from_user_account_id` (one character off a real one) must not cost the pair
    /// its amount — `from_amount` applies as long as both sides matched.
    @Test("Unknown account id on FROM only → pair resolved and the amount still applies")
    func unknownAccountIdOnFromSideKeepsAmount() {
        let candidates = [
            candidate(index: 0, token: "ethereum", network: "ethereum", account: 0, balance: 3),
            candidate(index: 1, token: "usd-coin", network: "ethereum", account: 0, balance: 1),
            candidate(index: 2, token: "solana", network: "solana", account: 0, balance: 100), // richest, must not win
        ]
        let result = select(
            candidates: candidates,
            params: params(
                fromToken: "ethereum",
                fromNetwork: "ethereum",
                toToken: "usd-coin",
                toNetwork: "ethereum",
                fromAccountId: "one-character-off",
                fromAmount: "0.0008"
            ),
            existingAccounts: ["real-account": 0]
        )

        #expect(result?.source == candidates[0])
        #expect(result?.destination == candidates[1])
        #expect(result?.appliesExtras == true)
    }

    @Test("Valid from_user_account_id pins FROM to that account instead of the most-funded one")
    func fromAccountIdPinsAccount() {
        let candidates = [
            candidate(index: 0, token: "ethereum", network: "ethereum", account: 0, balance: 100), // most-funded
            candidate(index: 1, token: "ethereum", network: "ethereum", account: 1, balance: 5), // pinned target
        ]
        let result = select(
            candidates: candidates,
            params: params(fromToken: "ethereum", fromNetwork: "ethereum", fromAccountId: "acc-1"),
            existingAccounts: ["acc-0": 0, "acc-1": 1]
        )
        #expect(result?.source == candidates[1]) // account #1, though account #0 holds more
    }

    @Test("Valid from_user_account_id whose account lacks the token → best-effort source")
    func fromAccountIdWithoutTokenFallsBackToBestEffort() {
        let candidates = [
            candidate(index: 0, token: "ethereum", network: "ethereum", account: 0, balance: 100),
            candidate(index: 1, token: "bitcoin", network: "bitcoin", account: 1, balance: 3, swappable: true),
        ]
        // Pin FROM to account #1, which holds no ethereum → matched source is empty → best-effort.
        let result = select(
            candidates: candidates,
            params: params(fromToken: "ethereum", fromNetwork: "ethereum", fromAccountId: "acc-1"),
            existingAccounts: ["acc-0": 0, "acc-1": 1]
        )
        #expect(result?.source == candidates[0]) // best-effort most-funded (ethereum @ account #0)
        #expect(result?.appliesExtras == false) // FROM is best-effort, not the pinned request
    }

    // MARK: - Cases 6 & 9: amount-only / provider-only → Main

    @Test("Amount and provider without a FROM/TO pair → nil (they never drive selection on their own)")
    func amountOrProviderOnly() {
        let candidates = [candidate(index: 0, token: "ethereum", network: "ethereum", balance: 10)]
        #expect(select(candidates: candidates, params: params(fromAmount: "0.5", providerId: "changelly")) == nil)
    }

    // MARK: - Case 7: TO + amount, no FROM

    @Test("Only TO requested → best-effort source + TO preselected")
    func onlyToRequested() {
        let candidates = [
            candidate(index: 0, token: "ethereum", network: "ethereum", balance: 80, swappable: true), // best-effort source
            candidate(index: 1, token: "solana", network: "solana", balance: 3),
        ]
        let result = select(candidates: candidates, params: params(toToken: "solana", toNetwork: "solana"))
        #expect(result?.source == candidates[0])
        #expect(result?.destination == candidates[1])
    }

    // MARK: - Case 8: FROM + amount, no TO

    @Test("Only FROM requested and held → FROM preselected, TO left empty")
    func onlyFromRequested() {
        let candidates = [candidate(index: 0, token: "ethereum", network: "ethereum", balance: 10)]
        let result = select(candidates: candidates, params: params(fromToken: "ethereum", fromNetwork: "ethereum"))
        #expect(result?.source == candidates[0])
        #expect(result?.destination == nil)
    }

    // MARK: - Best-effort excludes non-swappable

    @Test("Best-effort source skips non-swappable tokens even if richer")
    func bestEffortSkipsNonSwappable() {
        let candidates = [
            candidate(index: 0, token: "some-nft", network: "ethereum", balance: 999, swappable: false),
            candidate(index: 1, token: "bitcoin", network: "bitcoin", balance: 20, swappable: true),
            candidate(index: 2, token: "solana", network: "solana", balance: 3),
        ]
        // FROM not held → best-effort must pick the swappable BTC, not the richer NFT.
        let result = select(
            candidates: candidates,
            params: params(fromToken: "ethereum", fromNetwork: "ethereum", toToken: "solana", toNetwork: "solana")
        )
        #expect(result?.source == candidates[1])
        #expect(result?.destination == candidates[2])
    }

    // MARK: - Source never coincides with destination

    @Test("FROM not held: best-effort source skips the token already chosen as TO")
    func bestEffortSourceExcludesDestination() {
        let candidates = [
            candidate(index: 0, token: "ethereum", network: "ethereum", balance: 30), // next-best swappable
            candidate(index: 1, token: "solana", network: "solana", balance: 100), // richest, but it's the TO
        ]
        // FROM (bitcoin) not held; TO (solana) is the richest swappable — without exclusion it would become source too.
        let result = select(
            candidates: candidates,
            params: params(fromToken: "bitcoin", fromNetwork: "bitcoin", toToken: "solana", toNetwork: "solana")
        )
        #expect(result?.source == candidates[0])
        #expect(result?.destination == candidates[1])
    }

    @Test("Same token requested on both sides → source kept, TO left empty")
    func sameTokenBothSidesDropsDestination() {
        let candidates = [candidate(index: 0, token: "usd-coin", network: "ethereum", balance: 50)]
        let result = select(
            candidates: candidates,
            params: params(fromToken: "usd-coin", fromNetwork: "ethereum", toToken: "usd-coin", toNetwork: "ethereum")
        )
        #expect(result?.source == candidates[0])
        #expect(result?.destination == nil)
        #expect(result?.appliesExtras == false)
    }

    // MARK: - Requested FROM must be swap-eligible

    @Test("Requested FROM that is held but not swappable → best-effort swappable source instead")
    func requestedFromNotSwappableFallsBackToBestEffort() {
        let candidates = [
            candidate(index: 0, token: "ethereum", network: "ethereum", balance: 100, swappable: false), // requested but not swappable
            candidate(index: 1, token: "bitcoin", network: "bitcoin", balance: 20, swappable: true), // best-effort
        ]
        let result = select(candidates: candidates, params: params(fromToken: "ethereum", fromNetwork: "ethereum"))
        #expect(result?.source == candidates[1])
        #expect(result?.appliesExtras == false)
    }
}

// MARK: - Builders

private extension DeeplinkSwapParametersResolverTests {
    func select(
        candidates: [Candidate],
        params: DeeplinkNavigationAction.Params,
        existingAccounts: [String: Int] = [:]
    ) -> (source: Candidate, destination: Candidate?, appliesExtras: Bool)? {
        DeeplinkSwapParametersResolver.selectCandidates(
            candidates: candidates,
            params: params,
            targetUserWalletId: walletId,
            existingAccounts: existingAccounts
        )
    }

    func candidate(
        index: Int,
        token: String,
        network: String,
        account: Int? = 0,
        balance: Decimal = 0,
        swappable: Bool = true
    ) -> Candidate {
        Candidate(
            index: index,
            tokenId: token,
            networkId: network,
            accountDerivationIndex: account,
            fiatBalance: balance,
            isSwappable: swappable
        )
    }

    func params(
        fromToken: String? = nil,
        fromNetwork: String? = nil,
        toToken: String? = nil,
        toNetwork: String? = nil,
        fromWalletId: String? = nil,
        toWalletId: String? = nil,
        fromAccountId: String? = nil,
        toAccountId: String? = nil,
        fromAmount: String? = nil,
        providerId: String? = nil
    ) -> DeeplinkNavigationAction.Params {
        var params = DeeplinkNavigationAction.Params.empty
        params.swapFromTokenId = fromToken
        params.swapFromNetworkId = fromNetwork
        params.swapToTokenId = toToken
        params.swapToNetworkId = toNetwork
        params.swapFromUserWalletId = fromWalletId
        params.swapToUserWalletId = toWalletId
        params.swapFromUserAccountId = fromAccountId
        params.swapToUserAccountId = toAccountId
        params.swapFromAmount = fromAmount
        params.swapProviderId = providerId
        return params
    }
}

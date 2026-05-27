//
//  CommonTokenFeeProvidersManagerSwitchTests.swift
//  TangemTests
//
//  Covers switchToProviderWithEnoughBalanceIfNeeded() and the [REDACTED_INFO] fix:
//  prevent fallback to an unsupported initial provider that would cause the DEX
//  provider to disappear with .error after a gasless USDT approve when toggle
//  USDTRevokeGaslessFee is OFF.
//

import Foundation
import Testing
import Combine
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("CommonTokenFeeProvidersManager — switchToProviderWithEnoughBalanceIfNeeded", .serialized)
struct CommonTokenFeeProvidersManagerSwitchTests {
    // MARK: - Fixtures

    private let ethTokenItem: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    private let usdtTokenItem: TokenItem = .token(
        .init(name: "USDT", symbol: "USDT", contractAddress: "0xUSDT", decimalCount: 6),
        .init(.ethereum(testnet: false), derivationPath: nil)
    )
    private let usdcTokenItem: TokenItem = .token(
        .init(name: "USDC", symbol: "USDC", contractAddress: "0xUSDC", decimalCount: 6),
        .init(.ethereum(testnet: false), derivationPath: nil)
    )

    private func makeFee(_ value: Decimal) -> BSDKFee {
        BSDKFee(BSDKAmount(with: .ethereum(testnet: false), value: value))
    }

    private func makeSuccessTokenFee(_ value: Decimal, tokenItem: TokenItem) -> TokenFee {
        TokenFee(option: .market, tokenItem: tokenItem, value: .success(makeFee(value)))
    }

    private func makeUnsupportedTokenFee(tokenItem: TokenItem) -> TokenFee {
        TokenFee(option: .market, tokenItem: tokenItem, value: .failure(TokenFeeProviderError.unsupportedByProvider))
    }

    private func makeApproveInput(multiplier: FeeMultiplier) -> TokenFeeProviderInputData {
        .approve(txData: Data(), toContractAddress: "0xC", feeMultiplier: multiplier)
    }

    // MARK: - Scenario A: balance covers fee → no switch

    @Test("Selected provider with sufficient balance keeps selection")
    func feeFitsBalance_keepsSelection() async {
        let eth = ControllableTokenFeeProviderStub(
            feeTokenItem: ethTokenItem,
            state: .available([.market: makeFee(0.001)]),
            balance: .loaded(0.005),
            selectedTokenFee: makeSuccessTokenFee(0.001, tokenItem: ethTokenItem)
        )

        let sut = CommonTokenFeeProvidersManager(
            feeProviders: [eth],
            initialSelectedProvider: eth
        )

        await sut.updateFees().value

        #expect(sut.selectedFeeProvider.feeTokenItem == ethTokenItem)
    }

    // MARK: - Scenario C: switch to idle when fee > balance

    @Test("Switches to idle provider when selected balance is insufficient")
    func feeExceedsBalance_idleAvailable_switchesToIdle() async {
        let eth = ControllableTokenFeeProviderStub(
            feeTokenItem: ethTokenItem,
            state: .available([.market: makeFee(0.001)]),
            balance: .loaded(0.0001),
            selectedTokenFee: makeSuccessTokenFee(0.001, tokenItem: ethTokenItem)
        )
        let usdt = ControllableTokenFeeProviderStub(
            feeTokenItem: usdtTokenItem,
            state: .idle,
            balance: .loaded(100),
            selectedTokenFee: TokenFee(option: .market, tokenItem: usdtTokenItem, value: .loading)
        )

        let sut = CommonTokenFeeProvidersManager(
            feeProviders: [eth, usdt],
            initialSelectedProvider: eth
        )

        await sut.updateFees().value

        #expect(sut.selectedFeeProvider.feeTokenItem == usdtTokenItem)
    }

    // MARK: - Scenario D: fallback to initial when no idle and initial is supported

    @Test("Falls back to initial when no idle and initial is supported")
    func feeExceedsBalance_noIdle_initialSupported_fallsBackToInitial() async {
        // initial = USDT (supported, .available with USDT-fee that DOES cover its USDT-balance).
        // Selected has been forced to ETH (insufficient balance) — to mimic this we construct
        // the manager with USDT as both initial and selected, then put USDT into .notSupported
        // and call update(input:) so the manager auto-switches selected to ETH.
        // Once on ETH (insufficient balance, no idle), bring USDT BACK to a supported state
        // so the fallback step can pick it.
        let eth = ControllableTokenFeeProviderStub(
            feeTokenItem: ethTokenItem,
            state: .available([.market: makeFee(0.001)]),
            balance: .loaded(0),
            selectedTokenFee: makeSuccessTokenFee(0.001, tokenItem: ethTokenItem)
        )
        let usdt = ControllableTokenFeeProviderStub(
            feeTokenItem: usdtTokenItem,
            state: .idle,
            balance: .loaded(100),
            selectedTokenFee: makeSuccessTokenFee(1, tokenItem: usdtTokenItem)
        )

        let sut = CommonTokenFeeProvidersManager(
            feeProviders: [eth, usdt],
            initialSelectedProvider: usdt
        )

        // Step 1: usdt becomes .notSupported (e.g. triple+gasless+toggle off) → update() switches selected to eth.
        usdt.set(state: .unavailable(.notSupported))
        sut.update(input: makeApproveInput(multiplier: .triple))
        #expect(sut.selectedFeeProvider.feeTokenItem == ethTokenItem)

        // Step 2: usdt is BACK to supported (.available); idle no longer present.
        usdt.set(state: .available([.market: makeFee(1)]))

        await sut.updateFees().value

        // ETH fee=0.001 > balance=0, no .idle provider, initial(usdt) is supported → fallback to usdt.
        #expect(sut.selectedFeeProvider.feeTokenItem == usdtTokenItem)
    }

    // MARK: - Scenario E ([REDACTED_INFO] fix): no fallback when initial is .notSupported

    @Test("[REDACTED_INFO]: keeps current selection when no idle and initial is .notSupported")
    func feeExceedsBalance_noIdle_initialNotSupported_keepsCurrent() async throws {
        // Bug repro: ETH=0, gasless USDT initially selected, revoke+approve needs .triple,
        // toggle USDTRevokeGaslessFee is OFF → USDT becomes .notSupported, manager moves
        // selected to ETH, fee in ETH is calculated but balance=0 → switchToProviderWithEnoughBalanceIfNeeded
        // looks for idle (none) and used to fall back to initial(USDT, .notSupported), causing
        // selectedTokenFee.value.get() to throw → DEX provider disappeared.
        let eth = ControllableTokenFeeProviderStub(
            feeTokenItem: ethTokenItem,
            state: .available([.market: makeFee(0.001)]),
            balance: .loaded(0),
            selectedTokenFee: makeSuccessTokenFee(0.001, tokenItem: ethTokenItem)
        )
        let usdt = ControllableTokenFeeProviderStub(
            feeTokenItem: usdtTokenItem,
            state: .idle,
            balance: .loaded(100),
            selectedTokenFee: makeUnsupportedTokenFee(tokenItem: usdtTokenItem)
        )

        let sut = CommonTokenFeeProvidersManager(
            feeProviders: [eth, usdt],
            initialSelectedProvider: usdt
        )

        // Simulate post-`setup(.approve(.triple))` state: USDT is gasless-not-supported.
        usdt.set(state: .unavailable(.notSupported))
        sut.update(input: makeApproveInput(multiplier: .triple))
        #expect(
            sut.selectedFeeProvider.feeTokenItem == ethTokenItem,
            "checkSelectedProviderIsSupported must move selected from .notSupported initial to ETH"
        )

        // Run the fallback chain: ETH fee(0.001) > balance(0), no idle (USDT is .notSupported, not .idle).
        await sut.updateFees().value

        // FIX assertion: stays on ETH instead of bouncing back to .notSupported initial.
        #expect(
            sut.selectedFeeProvider.feeTokenItem == ethTokenItem,
            "Must NOT fall back to initial when it is .notSupported — selected must remain on the working provider"
        )

        // Downstream sanity: ETH's selectedTokenFee resolves cleanly,
        // so revokeAndApproveTransactionFee(...) wouldn't throw `unsupportedByProvider`.
        let unwrapped = try sut.selectedFeeProvider.selectedTokenFee.value.get()
        #expect(unwrapped.amount.value == 0.001)
    }

    // MARK: - Scenario E with multiple gasless providers (USDT + USDC both .notSupported)

    @Test("[REDACTED_INFO]: same behavior with multiple gasless providers all .notSupported")
    func feeExceedsBalance_multipleGaslessNotSupported_keepsCurrent() async {
        let eth = ControllableTokenFeeProviderStub(
            feeTokenItem: ethTokenItem,
            state: .available([.market: makeFee(0.0002)]),
            balance: .loaded(0),
            selectedTokenFee: makeSuccessTokenFee(0.0002, tokenItem: ethTokenItem)
        )
        let usdt = ControllableTokenFeeProviderStub(
            feeTokenItem: usdtTokenItem,
            state: .idle,
            balance: .loaded(20),
            selectedTokenFee: makeUnsupportedTokenFee(tokenItem: usdtTokenItem)
        )
        let usdc = ControllableTokenFeeProviderStub(
            feeTokenItem: usdcTokenItem,
            state: .idle,
            balance: .loaded(0),
            selectedTokenFee: makeUnsupportedTokenFee(tokenItem: usdcTokenItem)
        )

        let sut = CommonTokenFeeProvidersManager(
            feeProviders: [eth, usdt, usdc],
            initialSelectedProvider: usdt
        )

        usdt.set(state: .unavailable(.notSupported))
        usdc.set(state: .unavailable(.notSupported))
        sut.update(input: makeApproveInput(multiplier: .triple))
        #expect(sut.selectedFeeProvider.feeTokenItem == ethTokenItem)

        await sut.updateFees().value

        #expect(sut.selectedFeeProvider.feeTokenItem == ethTokenItem)
    }

    // MARK: - Single-approve gasless flow (POL=0, USDT>0): fix must NOT engage

    @Test("Single approve via gasless: selected stays on USDT, returned fee is gasless USDT fee")
    func singleApproveGasless_selectedStaysOnUsdt_feeInUsdt() async throws {
        // Mimics: Polygon coin balance = 0, USDT0 balance > 0, first-time approve (.single multiplier).
        // Initial = gasless USDT0. update(input: .approve(.single)) does NOT mark anyone .notSupported.
        // updateFees on USDT0 returns USDT-fee. switchToProviderWithEnoughBalanceIfNeeded sees
        // balance(20) > fee(0.5) → early return on the "balance covers fee" guard. Our guard is
        // not reached at all.
        let pol = ControllableTokenFeeProviderStub(
            feeTokenItem: ethTokenItem, // representing the chain's coin (Polygon role)
            state: .unavailable(.noTokenBalance),
            balance: .loaded(0),
            selectedTokenFee: TokenFee(
                option: .market,
                tokenItem: ethTokenItem,
                value: .failure(TokenFeeProviderError.providerUnavailable)
            )
        )
        let gaslessUsdtFee: Decimal = 0.5
        let usdt = ControllableTokenFeeProviderStub(
            feeTokenItem: usdtTokenItem,
            state: .available([.market: makeFee(gaslessUsdtFee)]),
            balance: .loaded(20),
            selectedTokenFee: makeSuccessTokenFee(gaslessUsdtFee, tokenItem: usdtTokenItem)
        )

        let sut = CommonTokenFeeProvidersManager(
            feeProviders: [pol, usdt],
            initialSelectedProvider: usdt
        )

        let approveData = ApproveTransactionData(
            txData: Data([0xAA]),
            spender: "0xSpender",
            toContractAddress: "0xC"
        )
        let returnedFee = try await sut.transactionFee(approveData: approveData)

        // Selected stayed on gasless USDT (no .notSupported promotion happened, no switch needed).
        #expect(sut.selectedFeeProvider.feeTokenItem == usdtTokenItem)
        // Returned fee is the gasless USDT fee, not a Polygon-coin fee.
        #expect(returnedFee.amount.value == gaslessUsdtFee)

        // setup() was called with .single multiplier — our guard's trigger condition (.triple) is absent.
        guard let lastUsdtSetup = usdt.setupCalls.last,
              case .approve(_, _, let multiplier) = lastUsdtSetup
        else {
            Issue.record("Expected last setup() call on USDT to be .approve")
            return
        }
        #expect(multiplier == .single, "Single approve must use .single multiplier — only .triple triggers the gasless-not-supported promotion")
    }

    // MARK: - Early return: current is not .available

    @Test("No-op when current selected has no fee value (e.g. .notSupported)")
    func currentHasNoFee_earlyReturn_noSwitch() async {
        // Current ETH is .notSupported → selectedTokenFee.value resolves to .failure → .value is nil.
        // First guard early-returns: switchToProviderWithEnoughBalanceIfNeeded does nothing.
        let eth = ControllableTokenFeeProviderStub(
            feeTokenItem: ethTokenItem,
            state: .unavailable(.notSupported),
            balance: .loaded(0),
            selectedTokenFee: makeUnsupportedTokenFee(tokenItem: ethTokenItem)
        )
        let usdt = ControllableTokenFeeProviderStub(
            feeTokenItem: usdtTokenItem,
            state: .idle,
            balance: .loaded(100),
            selectedTokenFee: TokenFee(option: .market, tokenItem: usdtTokenItem, value: .loading)
        )

        let sut = CommonTokenFeeProvidersManager(
            feeProviders: [eth, usdt],
            initialSelectedProvider: eth
        )

        await sut.updateFees().value

        // No switch — selected stays on ETH (the .notSupported provider).
        // Switch logic relies on a real fee value to compare against balance; without it, it bails out.
        #expect(sut.selectedFeeProvider.feeTokenItem == ethTokenItem)
    }

    @Test("No-op when balance is not .loaded (e.g. .empty/.loading/.failure)")
    func balanceNotLoaded_earlyReturn_noSwitch() async {
        // Current ETH is .available with a fee, but balance is still loading → balance.loaded == nil.
        // Switch would otherwise want to swap to idle USDT — but bails out at the first guard.
        let eth = ControllableTokenFeeProviderStub(
            feeTokenItem: ethTokenItem,
            state: .available([.market: makeFee(0.001)]),
            balance: .loading(nil),
            selectedTokenFee: makeSuccessTokenFee(0.001, tokenItem: ethTokenItem)
        )
        let usdt = ControllableTokenFeeProviderStub(
            feeTokenItem: usdtTokenItem,
            state: .idle,
            balance: .loaded(100),
            selectedTokenFee: TokenFee(option: .market, tokenItem: usdtTokenItem, value: .loading)
        )

        let sut = CommonTokenFeeProvidersManager(
            feeProviders: [eth, usdt],
            initialSelectedProvider: eth
        )

        await sut.updateFees().value

        #expect(sut.selectedFeeProvider.feeTokenItem == ethTokenItem)
    }

    // MARK: - Negative guard: provider with .unavailable(.noTokenBalance) is still .isSupported

    @Test("Initial in .unavailable(.noTokenBalance) is still treated as supported and used as fallback")
    func feeExceedsBalance_noIdle_initialNoTokenBalance_fallsBackToInitial() async {
        // .unavailable(.noTokenBalance) returns isSupported = true (see TokenFeeProviderState.isSupported).
        // The fix must NOT block the fallback in this case — only .notSupported should.
        let eth = ControllableTokenFeeProviderStub(
            feeTokenItem: ethTokenItem,
            state: .available([.market: makeFee(0.001)]),
            balance: .loaded(0),
            selectedTokenFee: makeSuccessTokenFee(0.001, tokenItem: ethTokenItem)
        )
        let usdt = ControllableTokenFeeProviderStub(
            feeTokenItem: usdtTokenItem,
            state: .unavailable(.noTokenBalance),
            balance: .loaded(0),
            selectedTokenFee: makeSuccessTokenFee(1, tokenItem: usdtTokenItem)
        )

        let sut = CommonTokenFeeProvidersManager(
            feeProviders: [eth, usdt],
            initialSelectedProvider: usdt
        )

        // Selected starts as USDT(noTokenBalance) — checkSelectedProviderIsSupported leaves it
        // alone because isSupported == true. Manually switch to ETH to set up the scenario.
        sut.updateSelectedFeeProvider(feeTokenItem: ethTokenItem)
        #expect(sut.selectedFeeProvider.feeTokenItem == ethTokenItem)

        await sut.updateFees().value

        // ETH fee > balance, no idle, initial(usdt) IS supported (noTokenBalance != notSupported)
        // → fallback to usdt should still happen (fix only kicks in for .notSupported).
        #expect(sut.selectedFeeProvider.feeTokenItem == usdtTokenItem)
    }
}

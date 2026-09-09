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
@testable import BlockchainSdk
import BigInt
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
            initialSelectedProvider: eth,
            ownerAddress: nil
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
            initialSelectedProvider: eth,
            ownerAddress: nil
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
            initialSelectedProvider: usdt,
            ownerAddress: nil
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
            initialSelectedProvider: usdt,
            ownerAddress: nil
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
            initialSelectedProvider: usdt,
            ownerAddress: nil
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
            initialSelectedProvider: usdt,
            ownerAddress: nil
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
            initialSelectedProvider: eth,
            ownerAddress: nil
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
            initialSelectedProvider: eth,
            ownerAddress: nil
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
            initialSelectedProvider: usdt,
            ownerAddress: nil
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

@Suite("CommonTokenFeeProvidersManagerProvider — initial selection")
struct CommonTokenFeeProvidersManagerProviderInitialSelectionTests {
    private let tronNativeTokenItem: TokenItem = .blockchain(.init(.tron(testnet: false), derivationPath: nil))
    private let tronTokenItem: TokenItem = .token(
        .init(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
            decimalCount: 6
        ),
        .init(.tron(testnet: false), derivationPath: nil)
    )
    @Test("Tron selects gasless token when both fee currencies have balance")
    func tronWithNativeAndGaslessBalances_selectsGasless() {
        let native = makeProvider(tokenItem: tronNativeTokenItem, balance: 10)
        let gasless = makeProvider(tokenItem: tronTokenItem, balance: 100)

        let selected = makeSUT().prepareInitialTokenFeeProvider(main: native, all: [native, gasless])

        #expect(selected.feeTokenItem == tronTokenItem)
    }

    @Test("Tron selects gasless token when native balance is zero")
    func tronWithOnlyGaslessBalance_selectsGasless() {
        let native = makeProvider(tokenItem: tronNativeTokenItem, balance: 0)
        let gasless = makeProvider(tokenItem: tronTokenItem, balance: 100)

        let selected = makeSUT().prepareInitialTokenFeeProvider(main: native, all: [native, gasless])

        #expect(selected.feeTokenItem == tronTokenItem)
    }

    @Test("Tron selects native token when gasless balance is zero")
    func tronWithoutGaslessBalance_selectsNative() {
        let native = makeProvider(tokenItem: tronNativeTokenItem, balance: 10)
        let gasless = makeProvider(tokenItem: tronTokenItem, balance: 0)

        let selected = makeSUT().prepareInitialTokenFeeProvider(main: native, all: [native, gasless])

        #expect(selected.feeTokenItem == tronNativeTokenItem)
    }

    @Test("Tron selects native token when no gasless provider exists")
    func tronWithoutGaslessProvider_selectsNative() {
        let native = makeProvider(tokenItem: tronNativeTokenItem, balance: 10)

        let selected = makeSUT().prepareInitialTokenFeeProvider(main: native, all: [native])

        #expect(selected.feeTokenItem == tronNativeTokenItem)
    }

    @Test("Tron keeps native fallback when neither fee currency has balance")
    func tronWithoutFeeCurrencyBalances_selectsNative() {
        let native = makeProvider(tokenItem: tronNativeTokenItem, balance: 0)
        let gasless = makeProvider(tokenItem: tronTokenItem, balance: 0)

        let selected = makeSUT().prepareInitialTokenFeeProvider(main: native, all: [native, gasless])

        #expect(selected.feeTokenItem == tronNativeTokenItem)
    }

    private func makeSUT() -> CommonTokenFeeProvidersManagerProvider {
        CommonTokenFeeProvidersManagerProvider(
            walletModel: WalletModelTestsMock(tokenItem: tronTokenItem, isEmpty: false)
        )
    }

    private func makeProvider(tokenItem: TokenItem, balance: Decimal) -> ControllableTokenFeeProviderStub {
        ControllableTokenFeeProviderStub(
            feeTokenItem: tokenItem,
            balance: .loaded(balance),
            selectedTokenFee: TokenFee(option: .market, tokenItem: tokenItem, value: .loading)
        )
    }
}

@Suite("CommonTokenFeeProvidersManagerProvider — Tron gasless availability", .serialized)
struct CommonTokenFeeProvidersManagerProviderTronGaslessAvailabilityTests {
    private let feeTokenAddress = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"
    private let unsupportedTokenAddress = "TEkxiTehnzSmSe2XqrBj4w32RUN966rdz8"

    @Test("Activated Tron account exposes the sent token when it supports gasless fees")
    func activatedAccountWithSupportedToken_exposesSentToken() async {
        await assertAvailableTokenAddresses(
            tokenAddress: feeTokenAddress,
            isAccountActivated: true,
            expectedAddresses: [feeTokenAddress]
        )
    }

    @Test("Non-activated Tron account hides gasless fee tokens")
    func nonActivatedAccount_hidesGaslessFeeTokens() async {
        await assertAvailableTokenAddresses(
            tokenAddress: feeTokenAddress,
            isAccountActivated: false,
            expectedAddresses: []
        )
    }

    @Test("Activated Tron account hides fee tokens different from the token being sent")
    func activatedAccountWithUnsupportedToken_hidesGaslessFeeTokens() async {
        await assertAvailableTokenAddresses(
            tokenAddress: unsupportedTokenAddress,
            isAccountActivated: true,
            expectedAddresses: []
        )
    }

    private func assertAvailableTokenAddresses(
        tokenAddress: String,
        isAccountActivated: Bool,
        expectedAddresses: [String]
    ) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousNetworkManager = InjectedValues[\.gaslessTransactionsNetworkManager]
            defer {
                InjectedValues[\.gaslessTransactionsNetworkManager] = previousNetworkManager
            }

            InjectedValues[\.gaslessTransactionsNetworkManager] = GaslessTransactionsNetworkManagerStub(
                feeRecipientAddress: nil,
                tronFeeTokens: [
                    .init(
                        address: feeTokenAddress,
                        symbol: "USDT",
                        decimals: 6,
                        chain: "tron"
                    ),
                ]
            )

            let walletModel = WalletModelTestsMock(
                tokenItem: .token(
                    .init(
                        name: "Token",
                        symbol: "TOKEN",
                        contractAddress: tokenAddress,
                        decimalCount: 6
                    ),
                    .init(.tron(testnet: false), derivationPath: nil)
                ),
                isEmpty: false
            )
            walletModel.tronAccountActivationStateProviderMock = TronAccountActivationStateProviderStub(
                isAccountActivated: isAccountActivated
            )

            let sut = CommonTokenFeeProvidersManagerProvider(
                walletModel: walletModel,
                isFeatureAvailable: { $0 == .tronGasless }
            )

            #expect(sut.availableGaslessTokenAddresses() == expectedAddresses)
        }
    }
}

@Suite("Tron gasless quote request", .serialized)
struct TronGaslessQuoteRequestTests {
    private let sourceAddress = "TSourceAddress"
    private let destinationAddress = "TDestinationAddress"
    private let tokenContractAddress = "TTokenContract"
    private let feeTokenContractAddress = "TFeeTokenContract"

    @Test("Quote matches the transaction built from the estimated amount")
    func matchingTransaction_isRecognized() {
        let transaction = makeTransaction(amount: 3)
        let request = makeRequest(amountRaw: "3000000")

        #expect(request.matches(transaction: transaction, feeToken: makeFeeToken()))
    }

    @Test("Quote does not match a fee-adjusted transaction amount")
    func feeAdjustedTransaction_requiresNewQuote() {
        let transaction = makeTransaction(amount: Decimal(string: "0.4662")!)
        let request = makeRequest(amountRaw: "3000000")

        #expect(!request.matches(transaction: transaction, feeToken: makeFeeToken()))
    }

    @Test("Quote matches a fee-adjusted amount before the transaction is built")
    func feeAdjustedAmount_isRecognized() {
        let blockchain = BSDKBlockchain.tron(testnet: false)
        let token = BSDKToken(
            name: "USDT",
            symbol: "USDT",
            contractAddress: tokenContractAddress,
            decimalCount: 6
        )
        let amount = BSDKAmount(
            with: blockchain,
            type: .token(value: token),
            value: Decimal(string: "0.4662")!
        )
        let request = makeRequest(amountRaw: "466200")

        #expect(request.matches(
            amount: amount,
            destinationAddress: destinationAddress,
            feeToken: makeFeeToken()
        ))
    }

    @Test("Fee amount uses the raw compensation value")
    func feeAmount_usesRawCompensationValue() async throws {
        let networkManager = GaslessTransactionsNetworkManagerStub(
            feeRecipientAddress: nil,
            tronEstimate: { _ in
                try makeEstimateResponse(
                    compensationAmount: "2.5338",
                    compensationAmountRaw: "2533812"
                )
            }
        )

        let blockchain = BSDKBlockchain.tron(testnet: false)
        let token = Token(
            name: "USDT",
            symbol: "USDT",
            contractAddress: tokenContractAddress,
            decimalCount: 6
        )
        let feeToken = BSDKToken(
            name: token.name,
            symbol: token.symbol,
            contractAddress: token.contractAddress,
            decimalCount: token.decimalCount
        )
        let loader = CommonTronGaslessTokenFeeLoader(
            tokenItem: .token(token, .init(blockchain, derivationPath: nil)),
            feeToken: feeToken,
            sourceAddress: sourceAddress,
            networkManager: networkManager
        )

        let fees = try await loader.getFee(amount: 3, destination: destinationAddress)
        let fee = try #require(fees.first)

        #expect(fee.amount.value == Decimal(string: "2.533812"))
    }

    private func makeRequest(
        amountRaw: String,
        feeTokenContractAddress: String? = nil
    ) -> TronGaslessQuoteRequest {
        TronGaslessQuoteRequest(
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            tokenContractAddress: tokenContractAddress,
            amountRaw: amountRaw,
            feeTokenContractAddress: feeTokenContractAddress ?? self.feeTokenContractAddress
        )
    }

    private func makeTransaction(
        amount: Decimal,
        feeToken: BSDKToken? = nil,
        feeAmount: Decimal = 1,
        feeParameters: FeeParameters? = nil
    ) -> BSDKTransaction {
        let blockchain = BSDKBlockchain.tron(testnet: false)
        let token = BSDKToken(
            name: "USDT",
            symbol: "USDT",
            contractAddress: tokenContractAddress,
            decimalCount: 6
        )

        return BSDKTransaction(
            amount: BSDKAmount(with: blockchain, type: .token(value: token), value: amount),
            fee: BSDKFee(
                BSDKAmount(with: feeToken ?? makeFeeToken(), value: feeAmount),
                parameters: feeParameters
            ),
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: sourceAddress
        )
    }

    private func makeFeeToken() -> BSDKToken {
        BSDKToken(
            name: "Fee token",
            symbol: "FEE",
            contractAddress: feeTokenContractAddress,
            decimalCount: 6
        )
    }

    private func makeEstimateResponse(
        compensationAmount: String,
        compensationAmountRaw: String
    ) throws -> GaslessTransactionsDTO.Response.TronEstimate {
        let data = Data(
            """
            {
              "result": {
                "quoteId": "quote",
                "feeRecipient": "TFeeRecipient",
                "compensationToken": "\(tokenContractAddress)",
                "compensationAmount": "\(compensationAmount)",
                "compensationAmountRaw": "\(compensationAmountRaw)",
                "estimate": {
                  "energy": 1,
                  "bandwidth": 1,
                  "trxCost": "1"
                },
                "expiresAt": "2099-01-01T00:00:00Z"
              }
            }
            """.utf8
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(GaslessTransactionsDTO.Response.TronEstimate.self, from: data)
    }
}

@Suite("Gasless Yield Fee", .serialized)
struct GaslessYieldFeeTests {
    @Test("WithdrawMethod encodes withdraw(address,uint256) selector and params")
    func withdrawMethodEncoding() {
        let tokenAddress = "0x0000000000000000000000000000000000000001"
        let method = WithdrawMethod(
            tokenContractAddress: tokenAddress,
            amount: EthereumFeeParametersConstants.gaslessMinTokenAmount
        )

        #expect(method.encodedData.hasPrefix("0xf3fef3a3"))
        #expect(method.encodedData.contains(tokenAddress.removeHexPrefix()))
    }

    @Test("Gasless yield fee metadata survives gas-limit updates")
    func yieldFeeMetadataSurvivesGasLimitUpdate() {
        let yieldWithdraw = EthereumGaslessTransactionFeeParameters.YieldWithdraw(
            yieldContractAddress: "0x0000000000000000000000000000000000000002",
            withdrawGasLimit: 50_000,
            upgrade: .required(implementation: "0x0000000000000000000000000000000000000003")
        )
        let parameters = EthereumGaslessTransactionFeeParameters(
            gasLimit: 210_000,
            callGasLimit: 100_000,
            maxFeePerGas: 1_000,
            priorityFee: 100,
            nativeToFeeTokenRate: 1,
            feeTokenTransferGasLimit: 30_000,
            yieldWithdraw: yieldWithdraw
        )

        let updated = parameters.changingGasLimit(to: 300_000)

        #expect(updated.gasLimit == 300_000)
        #expect(updated.callGasLimit == 100_000)
        #expect(updated.yieldWithdraw == yieldWithdraw)
    }

    @Test("Batch EIP-712 typed data includes transactions array and gasLimit")
    func batchTypedDataShape() {
        let transaction = GaslessTransactionsDTO.Request.GaslessTransaction.TransactionData.Transaction(
            to: "0x0000000000000000000000000000000000000001",
            value: "0",
            gasLimit: "21000",
            data: "0x"
        )
        let fee = GaslessTransactionsDTO.Request.GaslessTransaction.TransactionData.Fee(
            feeToken: "0x0000000000000000000000000000000000000002",
            maxTokenFee: "10000",
            coinPriceInToken: "1",
            feeTransferGasLimit: "50000",
            baseGas: "60000",
            feeReceiver: "0x0000000000000000000000000000000000000003"
        )

        let typedData = GaslessTransactionBuilder.GaslessTransactionsEIP712Util().makeGaslessBatchTypedData(
            transactions: [transaction],
            fee: fee,
            nonce: "0",
            chainId: 1,
            verifyingContract: "0x0000000000000000000000000000000000000004"
        )

        #expect(typedData.primaryType == "GaslessBatchTransaction")
        #expect(typedData.types["Transaction"]?.contains { $0.name == "gasLimit" && $0.type == "uint256" } == true)
        #expect(typedData.types["GaslessBatchTransaction"]?.contains { $0.name == "transactions" && $0.type == "Transaction[]" } == true)
        #expect(typedData.message.objectValue?["transactions"]?.arrayValue?.first?.objectValue?["gasLimit"]?.stringValue == "21000")
    }

    /// The encoded type strings are hashed into the signed digest, so they have to match
    /// `Tangem7702GaslessExecutor` byte for byte. The literals below are copied from the deployed contract.
    @Test("Batch-capable executor type strings match the deployed contract")
    func batchCapableTypeStringsMatchContract() throws {
        let util = GaslessTransactionBuilder.GaslessTransactionsEIP712Util()
        let feeType = "Fee(address feeToken,uint256 maxTokenFee,uint256 coinPriceInToken,uint256 feeTransferGasLimit,uint256 baseGas,address feeReceiver)"
        let transactionType = "Transaction(address to,uint256 value,uint256 gasLimit,bytes data)"

        let single = try util.makeGaslessTypedData(
            transaction: Self.stubTransaction(gasLimit: "21000"),
            fee: Self.stubFee(),
            nonce: "0",
            chainId: 1,
            verifyingContract: Self.stubVerifyingContract,
            executorVersion: .batchCapable
        )
        let batch = util.makeGaslessBatchTypedData(
            transactions: [Self.stubTransaction(gasLimit: "21000")],
            fee: Self.stubFee(),
            nonce: "0",
            chainId: 1,
            verifyingContract: Self.stubVerifyingContract
        )

        #expect(
            String(decoding: single.makeTypeData(primaryType: "GaslessTransaction"), as: UTF8.self)
                == "GaslessTransaction(Transaction transaction,Fee fee,uint256 nonce)" + feeType + transactionType
        )
        #expect(
            String(decoding: batch.makeTypeData(primaryType: "GaslessBatchTransaction"), as: UTF8.self)
                == "GaslessBatchTransaction(Transaction[] transactions,Fee fee,uint256 nonce)" + feeType + transactionType
        )
    }

    /// Golden digests produced by `ethers.TypedDataEncoder.hash` over the type definitions in the contract
    /// repository's own `test/helpers/eip712Gasless.js`, for the payload built below. They pin our hashing to an
    /// independent implementation, so a regression in either the types or the encoder shows up here.
    @Test("Signed digests match the reference EIP-712 encoder")
    func digestsMatchReferenceEncoder() throws {
        let util = GaslessTransactionBuilder.GaslessTransactionsEIP712Util()

        let single = try util.makeGaslessTypedData(
            transaction: Self.stubTransaction(gasLimit: "21000"),
            fee: Self.stubFee(),
            nonce: "0",
            chainId: 1,
            verifyingContract: Self.stubVerifyingContract,
            executorVersion: .batchCapable
        )
        let batch = util.makeGaslessBatchTypedData(
            transactions: [Self.stubTransaction(gasLimit: "21000")],
            fee: Self.stubFee(),
            nonce: "0",
            chainId: 1,
            verifyingContract: Self.stubVerifyingContract
        )

        #expect(single.signHash.hexString.lowercased() == "9e385b7d4a71cc70496d0f1f1d2ab5fda665d617cbb0ea26a99c79a4cec21cf4")
        #expect(batch.signHash.hexString.lowercased() == "0dda1b2d4786084e451e9b6b90d386d6ae685b4405b59d134e667bdcbc45ff1a")
    }

    @Test("Legacy executor signs the pre-batch Transaction type without a gas limit")
    func legacyExecutorOmitsCallGasLimit() throws {
        let typedData = try GaslessTransactionBuilder.GaslessTransactionsEIP712Util().makeGaslessTypedData(
            transaction: Self.stubTransaction(gasLimit: nil),
            fee: Self.stubFee(),
            nonce: "0",
            chainId: 1,
            verifyingContract: Self.stubVerifyingContract,
            executorVersion: .legacy
        )

        #expect(
            String(decoding: typedData.makeTypeData(primaryType: "Transaction"), as: UTF8.self)
                == "Transaction(address to,uint256 value,bytes data)"
        )
        #expect(typedData.message.objectValue?["transaction"]?.objectValue?["gasLimit"] == nil)
    }

    /// Signing `gasLimit: 0` would leave the executor forwarding no gas to the user's call, so a missing
    /// value has to fail before the user is asked to sign.
    @Test("Batch-capable executor rejects a transaction without a call gas limit")
    func batchCapableRequiresCallGasLimit() {
        #expect(throws: GaslessTransactionBuilder.GaslessTransactionBuilderError.self) {
            try GaslessTransactionBuilder.GaslessTransactionsEIP712Util().makeGaslessTypedData(
                transaction: Self.stubTransaction(gasLimit: nil),
                fee: Self.stubFee(),
                nonce: "0",
                chainId: 1,
                verifyingContract: Self.stubVerifyingContract,
                executorVersion: .batchCapable
            )
        }
    }

    @Test("Batch request uses v2 route and documented payload key")
    func batchRequestUsesV2Contract() throws {
        let transaction = GaslessTransactionsDTO.Request.GaslessTransaction.TransactionData.Transaction(
            to: "0x0000000000000000000000000000000000000001",
            value: "0",
            gasLimit: "21000",
            data: "0x"
        )
        let fee = GaslessTransactionsDTO.Request.GaslessTransaction.TransactionData.Fee(
            feeToken: "0x0000000000000000000000000000000000000002",
            maxTokenFee: "10000",
            coinPriceInToken: "1",
            feeTransferGasLimit: "50000",
            baseGas: "60000",
            feeReceiver: "0x0000000000000000000000000000000000000003"
        )
        let batchTransaction = GaslessTransactionsDTO.Request.GaslessBatchTransaction(
            gaslessTransaction: .init(transactions: [transaction], fee: fee, nonce: "0"),
            signature: "0xsignature",
            userAddress: "0x0000000000000000000000000000000000000004",
            chainId: 137,
            eip7702auth: .init(
                chainId: 137,
                address: "0x0000000000000000000000000000000000000005",
                nonce: "1",
                yParity: 0,
                r: "0xr",
                s: "0xs"
            )
        )

        let target = GaslessTransactionsAPITarget(apiType: .prod, target: .sendGaslessBatchTransaction(transaction: batchTransaction))
        let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(batchTransaction)) as? [String: Any]

        #expect(target.baseURL.absoluteString == "https://gasless.tangem.org/api/v2")
        #expect(encoded?["gaslessTransaction"] != nil)
        #expect(encoded?["gaslessBatchTransaction"] == nil)
    }

    @Test("Yield fee remains reachable when the plain gasless quote reverts")
    func yieldFeeReachableAfterPlainGaslessQuoteRevert() async throws {
        let previousNetworkManager = InjectedValues[\.gaslessTransactionsNetworkManager]
        InjectedValues[\.gaslessTransactionsNetworkManager] = GaslessTransactionsNetworkManagerStub(
            feeRecipientAddress: "0x0000000000000000000000000000000000000001"
        )
        defer {
            InjectedValues[\.gaslessTransactionsNetworkManager] = previousNetworkManager
        }

        let blockchain = BSDKBlockchain.polygon(testnet: false)
        let token = Token(
            name: "USDT",
            symbol: "USDT",
            contractAddress: "0x0000000000000000000000000000000000000002",
            decimalCount: 6,
            id: blockchain.coinId
        )
        let feeToken = BSDKToken(
            name: token.name,
            symbol: token.symbol,
            contractAddress: token.contractAddress,
            decimalCount: token.decimalCount,
            id: token.id
        )
        let yieldFee = BSDKFee(BSDKAmount(with: blockchain, type: .token(value: feeToken), value: 2))
        let feeProvider = GaslessTransactionFeeProviderStub(
            plainError: JSONRPC.APIError(code: 3, message: "ERC20: transfer amount exceeds balance"),
            yieldFee: yieldFee
        )

        let sut = CommonGaslessTokenFeeLoader(
            tokenItem: .token(token, .init(blockchain, derivationPath: nil)),
            feeToken: feeToken,
            gaslessTransactionFeeProvider: feeProvider,
            yieldFeeContext: GaslessYieldFeeContext(
                yieldContractAddress: "0x0000000000000000000000000000000000000003",
                yieldModuleBalance: 100,
                feeTokenBalanceProvider: TokenBalanceProviderTestsMock(balance: 120),
                versionChecker: nil
            )
        )

        let fees = try await sut.getFee(
            amount: 1,
            destination: "0x0000000000000000000000000000000000000004"
        )

        #expect(fees.count == 1)
        #expect(fees.first?.amount.value == yieldFee.amount.value)
        #expect(feeProvider.getGaslessFeeCallCount == 1)
        #expect(feeProvider.getGaslessYieldFeeCallCount == 1)
    }
}

private extension GaslessYieldFeeTests {
    static let stubVerifyingContract = "0x0000000000000000000000000000000000000004"

    static func stubTransaction(gasLimit: String?) -> GaslessTransactionsDTO.Request.GaslessTransaction.TransactionData.Transaction {
        .init(
            to: "0x0000000000000000000000000000000000000001",
            value: "0",
            gasLimit: gasLimit,
            data: "0x"
        )
    }

    static func stubFee() -> GaslessTransactionsDTO.Request.GaslessTransaction.TransactionData.Fee {
        .init(
            feeToken: "0x0000000000000000000000000000000000000002",
            maxTokenFee: "10000",
            coinPriceInToken: "1",
            feeTransferGasLimit: "50000",
            baseGas: "60000",
            feeReceiver: "0x0000000000000000000000000000000000000003"
        )
    }
}

final class GaslessTransactionFeeProviderStub: GaslessTransactionFeeProvider {
    private let plainError: Error?
    private let plainFee: BSDKFee
    private let yieldFee: BSDKFee

    private(set) var getGaslessFeeCallCount = 0
    private(set) var getGaslessYieldFeeCallCount = 0

    init(plainError: Error?, plainFee: BSDKFee? = nil, yieldFee: BSDKFee) {
        self.plainError = plainError
        self.plainFee = plainFee ?? yieldFee
        self.yieldFee = yieldFee
    }

    func getGaslessFee(
        feeToken: BSDKToken,
        amount: BSDKAmount,
        destination: String,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal
    ) async throws -> BSDKFee {
        getGaslessFeeCallCount += 1

        if let plainError {
            throw plainError
        }

        return plainFee
    }

    func getEstimatedGaslessFee(
        feeToken: BSDKToken,
        amount: BSDKAmount,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal
    ) async throws -> BSDKFee {
        if let plainError {
            throw plainError
        }

        return plainFee
    }

    func getEstimatedGaslessYieldFee(
        feeToken: BSDKToken,
        amount: BSDKAmount,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal,
        yieldFeeOptions: YieldFeeOptions
    ) async throws -> BSDKFee {
        yieldFee
    }

    func getGaslessTransactionFee(
        feeToken: BSDKToken,
        destination: String,
        value: String?,
        data: Data?,
        stateOverride: EthereumStateOverride?,
        otherNativeFee: Decimal?,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal
    ) async throws -> BSDKFee {
        if let plainError {
            throw plainError
        }

        return plainFee
    }

    func getEstimatedGaslessTransactionFee(
        feeToken: BSDKToken,
        estimatedGasLimit: Int,
        otherNativeFee: Decimal?,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal
    ) async throws -> BSDKFee {
        if let plainError {
            throw plainError
        }

        return plainFee
    }

    func getGaslessYieldFee(
        feeToken: BSDKToken,
        amount: BSDKAmount,
        destination: String,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal,
        yieldFeeOptions: YieldFeeOptions
    ) async throws -> BSDKFee {
        getGaslessYieldFeeCallCount += 1
        return yieldFee
    }

    func getGaslessYieldTransactionFee(
        feeToken: BSDKToken,
        destination: String,
        value: String?,
        data: Data?,
        otherNativeFee: Decimal?,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal,
        yieldFeeOptions: YieldFeeOptions
    ) async throws -> BSDKFee {
        yieldFee
    }

    func getEstimatedGaslessYieldTransactionFee(
        feeToken: BSDKToken,
        estimatedGasLimit: Int,
        otherNativeFee: Decimal?,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal,
        yieldFeeOptions: YieldFeeOptions
    ) async throws -> BSDKFee {
        yieldFee
    }
}

private final class GaslessTransactionsNetworkManagerStub: GaslessTransactionsNetworkManager {
    let cachedFeeRecipientAddress: String?
    private let tronEstimate: ((TronEstimateRequest) async throws -> TronEstimateResponse)?
    private let tronFeeTokens: [TronFeeToken]

    var availableFeeTokens: [FeeToken] { [] }
    var availableFeeTokensPublisher: AnyPublisher<[FeeToken], Never> {
        Just([]).eraseToAnyPublisher()
    }

    var availableTronFeeTokens: [TronFeeToken] { tronFeeTokens }
    var availableTronFeeTokensPublisher: AnyPublisher<[TronFeeToken], Never> {
        Just(tronFeeTokens).eraseToAnyPublisher()
    }

    var currentHost: String { "test" }
    var feeRecipientAddress: String? { cachedFeeRecipientAddress }

    init(
        feeRecipientAddress: String?,
        tronFeeTokens: [TronFeeToken] = [],
        tronEstimate: ((TronEstimateRequest) async throws -> TronEstimateResponse)? = nil
    ) {
        cachedFeeRecipientAddress = feeRecipientAddress
        self.tronFeeTokens = tronFeeTokens
        self.tronEstimate = tronEstimate
    }

    func updateAvailableTokens() {}
    func sendGaslessTransaction(_ transaction: GaslessTransaction, executorVersion: GaslessExecutorVersion) async throws -> String { "" }
    func sendGaslessBatchTransaction(_ transaction: GaslessBatchTransaction) async throws -> String { "" }
    func estimateTronGaslessTransaction(_ request: TronEstimateRequest) async throws -> TronEstimateResponse {
        guard let tronEstimate else {
            throw CancellationError()
        }

        return try await tronEstimate(request)
    }

    func submitTronGaslessTransaction(_ request: TronSubmitRequest) async throws -> TronSubmitResponse {
        throw CancellationError()
    }

    func initialize() {}
    func preloadFeeRecipientAddress() {}
}

private struct TronAccountActivationStateProviderStub: TronAccountActivationStateProvider {
    let isAccountActivated: Bool
}

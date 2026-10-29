//
//  CommonTokenFeeProviderTronRoutingTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Combine
import TangemFoundation
import BlockchainSdk
@testable import Tangem

@Suite("CommonTokenFeeProvider — Tron input routing")
struct CommonTokenFeeProviderTronRoutingTests {
    private let tronFeeTokenItem: TokenItem = .blockchain(.init(.tron(testnet: false), derivationPath: nil))

    @Test("a CEX preview without a deposit address uses the Tron estimation address")
    func cexInput_tronGaslessLoader_previewQuotesEstimationAddress() async throws {
        let networkManager = TronGaslessNetworkManagerStub(compensationAmountRaw: "2500000")
        let loader = makeTronGaslessLoader(networkManager: networkManager)
        let sut = makeSUT(loader: loader)

        sut.setup(input: .cex(amount: 10))
        await sut.updateFees().value

        let request = try #require(networkManager.estimateRequests.first)
        #expect(request.operation == .transfer(toAddress: "TA4Tkaj2nAJjkVbDHdUQDxYCbLfsZzS8pA"))
        #expect(request.amount == "10000000")
    }

    @Test("a disabled Tron gasless DEX feature keeps the transfer loader available")
    func gaslessDEXFeatureDisabled_transferLoaderStillAvailable() throws {
        let token = Token(
            name: "USDT",
            symbol: "USDT",
            contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
            decimalCount: 6
        )
        let walletModel = WalletModelTestsMock(
            tokenItem: .token(token, .init(.tron(testnet: false), derivationPath: nil)),
            isEmpty: false,
            addresses: [PlainAddress(value: "TSourceAddress", type: .default)]
        )
        walletModel.tronGaslessTransactionsBuilderMock = TronGaslessTransactionsBuilderStub()
        let sut = WalletModelTokenFeeLoaderProvider(
            walletModel: walletModel,
            isTronGaslessDEXEnabled: { false }
        )

        let loader = try #require(sut.makeGaslessTokenFeeLoader(
            feeToken: BSDKToken(
                name: token.name,
                symbol: token.symbol,
                contractAddress: token.contractAddress,
                decimalCount: token.decimalCount
            ),
            yieldFeeContext: nil
        ))

        #expect(loader.supports(.cex(amount: 10)))
        #expect(!loader.supports(.dex(.tron(request: makeRequest(), sourceAmount: 10, spender: "TSpender"))))
    }

    @Test("a Tron DEX input reaches the Tron loader and lands available")
    func dexTronInput_routesToTronLoader() async throws {
        let loader = TronTokenFeeLoaderSpy(fees: [makeFee(2)])
        let sut = makeSUT(loader: loader)
        let request = makeRequest()

        sut.setup(input: .dex(.tron(request: request, sourceAmount: 10, spender: "TSpender")))
        #expect(sut.state.isSupported)

        await sut.updateFees().value

        #expect(loader.receivedRequests == [request])
        let fee = try sut.selectedTokenFee.value.get()
        #expect(fee.amount.value == 2)
    }

    @Test("a Tron DEX input reaches the gasless loader as a swap estimate")
    func dexTronInput_routesToGaslessLoader() async throws {
        let networkManager = TronGaslessNetworkManagerStub(compensationAmountRaw: "2500000")
        let loader = makeTronGaslessLoader(networkManager: networkManager, isDEXEnabled: true)
        let sut = makeSUT(loader: loader)
        let callData = Data([0x31, 0x10, 0xC7, 0xB9])
        let request = TronFeeRequestData(
            amount: BSDKAmount(with: .tron(testnet: false), type: .coin, value: 0),
            destination: "TSwapContract",
            callData: callData,
            memo: nil,
            otherNativeFee: nil
        )

        sut.setup(input: .dex(.tron(request: request, sourceAmount: 10, spender: "TSpender")))
        await sut.updateFees().value

        let estimate = try #require(networkManager.estimateRequests.first)
        #expect(estimate.tokenContract == "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t")
        #expect(estimate.amount == "10000000")
        #expect(estimate.operation == .swap(.init(
            contractAddress: "TSwapContract",
            data: callData.hexString,
            spender: "TSpender"
        )))
    }

    @Test("a Tron DEX input is unsupported by the gasless loader while the feature is disabled")
    func dexTronInput_gaslessFeatureDisabled_notSupported() async {
        let networkManager = TronGaslessNetworkManagerStub(compensationAmountRaw: "2500000")
        let loader = makeTronGaslessLoader(networkManager: networkManager, isDEXEnabled: false)
        let sut = makeSUT(loader: loader)

        sut.setup(input: .dex(.tron(request: makeRequest(), sourceAmount: 10, spender: "TSpender")))
        await sut.updateFees().value

        #expect(networkManager.estimateRequests.isEmpty)
        guard case .unavailable(.notSupported) = sut.state else {
            Issue.record("Expected .unavailable(.notSupported), got \(sut.state)")
            return
        }
    }

    @Test("an approve input becomes a calldata-priced Tron request")
    func approveInput_routesToTronLoader() async throws {
        let txData = Data([0x09, 0x5E, 0xA7, 0xB3, 0xFF])
        let contractAddress = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"
        let loader = TronTokenFeeLoaderSpy(fees: [makeFee(3)])
        let sut = makeSUT(loader: loader)

        sut.setup(input: .approve(
            txData: txData,
            toContractAddress: contractAddress,
            spender: nil,
            amountRaw: 1,
            feeMultiplier: .single
        ))
        #expect(sut.state.isSupported)

        await sut.updateFees().value

        let expectedRequest = TronFeeRequestData(
            amount: BSDKAmount(with: .tron(testnet: false), type: .coin, value: 0),
            destination: contractAddress,
            callData: txData,
            memo: nil,
            otherNativeFee: nil
        )
        #expect(loader.receivedRequests == [expectedRequest])

        let fee = try sut.selectedTokenFee.value.get()
        #expect(fee.amount.value == 3)
    }

    @Test("an approve input reaches the gasless loader as an approve estimate")
    func approveInput_routesToGaslessLoader() async throws {
        let networkManager = TronGaslessNetworkManagerStub(compensationAmountRaw: "2500000")
        let loader = makeTronGaslessLoader(networkManager: networkManager, isDEXEnabled: true)
        let sut = makeSUT(loader: loader)
        let txData = Data([0x09, 0x5E, 0xA7, 0xB3])

        sut.setup(input: .approve(
            txData: txData,
            toContractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
            spender: "TSpender",
            amountRaw: 10_000_000,
            feeMultiplier: .single
        ))
        await sut.updateFees().value

        let estimate = try #require(networkManager.estimateRequests.first)
        #expect(estimate.amount == "10000000")
        #expect(estimate.operation == .approve(.init(spender: "TSpender")))
    }

    @Test("an approve input is unsupported by the gasless loader while the feature is disabled")
    func approveInput_gaslessFeatureDisabled_notSupported() async {
        let networkManager = TronGaslessNetworkManagerStub(compensationAmountRaw: "2500000")
        let loader = makeTronGaslessLoader(networkManager: networkManager, isDEXEnabled: false)
        let sut = makeSUT(loader: loader)

        sut.setup(input: .approve(
            txData: Data([0x09, 0x5E, 0xA7, 0xB3]),
            toContractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
            spender: "TSpender",
            amountRaw: 10_000_000,
            feeMultiplier: .single
        ))
        await sut.updateFees().value

        #expect(networkManager.estimateRequests.isEmpty)
        guard case .unavailable(.notSupported) = sut.state else {
            Issue.record("Expected .unavailable(.notSupported), got \(sut.state)")
            return
        }
    }

    @Test("a Tron DEX input is unsupported without a Tron loader")
    func dexTronInput_nonTronLoader_notSupported() {
        let sut = makeSUT(loader: DefaultTokenFeeLoader(loader: NonTronTokenFeeLoaderStub()))

        sut.setup(input: .dex(.tron(request: makeRequest(), sourceAmount: 10, spender: nil)))

        guard case .unavailable(.notSupported) = sut.state else {
            Issue.record("Expected .unavailable(.notSupported), got \(sut.state)")
            return
        }
    }

    @Test("a Tron DEX input reaches a gasless mock")
    func dexTronInput_routesToGaslessMock() async throws {
        let loader = TronGaslessFeeLoaderMock(fees: [makeFee(4)], isDEXEnabled: true)
        let sut = makeSUT(loader: loader)

        sut.setup(input: .dex(.tron(request: makeRequest(), sourceAmount: 10, spender: "TSpender")))
        #expect(sut.state.isSupported)

        await sut.updateFees().value

        #expect(loader.loadedInputs.count == 1)
        let fee = try sut.selectedTokenFee.value.get()
        #expect(fee.amount.value == 4)
    }

    @Test("a Tron DEX input skips a gasless mock while the feature is disabled")
    func dexTronInput_gaslessMockFeatureDisabled_notSupported() async {
        let loader = TronGaslessFeeLoaderMock(fees: [makeFee(4)], isDEXEnabled: false)
        let sut = makeSUT(loader: loader)

        sut.setup(input: .dex(.tron(request: makeRequest(), sourceAmount: 10, spender: "TSpender")))
        await sut.updateFees().value

        #expect(loader.loadedInputs.isEmpty)
        guard case .unavailable(.notSupported) = sut.state else {
            Issue.record("Expected .unavailable(.notSupported), got \(sut.state)")
            return
        }
    }

    @Test("an approve input is unsupported without a Tron or Ethereum loader")
    func approveInput_nonTronLoader_notSupported() {
        let sut = makeSUT(loader: DefaultTokenFeeLoader(loader: NonTronTokenFeeLoaderStub()))

        sut.setup(input: .approve(
            txData: Data([0xAB]),
            toContractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
            spender: nil,
            amountRaw: 1,
            feeMultiplier: .single
        ))

        guard case .unavailable(.notSupported) = sut.state else {
            Issue.record("Expected .unavailable(.notSupported), got \(sut.state)")
            return
        }
    }
}

// MARK: - Helpers

private extension CommonTokenFeeProviderTronRoutingTests {
    func makeSUT(loader: any TokenFeeLoader) -> CommonTokenFeeProvider {
        CommonTokenFeeProvider(
            feeTokenItem: tronFeeTokenItem,
            tokenFeeLoader: loader,
            customFeeProvider: nil,
            feeTokenItemBalanceProvider: MutableTokenBalanceProviderMock(balance: 25),
            supportingOptions: .all
        )
    }

    func makeRequest() -> TronFeeRequestData {
        TronFeeRequestData(
            amount: BSDKAmount(with: .tron(testnet: false), type: .coin, value: 50),
            destination: "TKJMd8JF5hevd2TQeSKvJzwQKgpRQVHpr6",
            callData: nil,
            memo: nil,
            otherNativeFee: nil
        )
    }

    func makeFee(_ value: Decimal) -> BSDKFee {
        BSDKFee(BSDKAmount(with: .tron(testnet: false), value: value))
    }

    func makeTronGaslessLoader(
        networkManager: TronGaslessNetworkManagerStub,
        isDEXEnabled: Bool = false
    ) -> CommonTronGaslessTokenFeeLoader {
        let token = Token(
            name: "USDT",
            symbol: "USDT",
            contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
            decimalCount: 6
        )
        return CommonTronGaslessTokenFeeLoader(
            tokenItem: .token(token, .init(.tron(testnet: false), derivationPath: nil)),
            feeToken: BSDKToken(
                name: token.name,
                symbol: token.symbol,
                contractAddress: token.contractAddress,
                decimalCount: token.decimalCount
            ),
            sourceAddress: "TSourceAddress",
            userWalletId: UserWalletId(value: Data("wallet".utf8)),
            isDEXEnabled: isDEXEnabled,
            networkManager: networkManager
        )
    }
}

// MARK: - Doubles

private enum StubError: Error {
    case notNeeded
}

private struct TronGaslessTransactionsBuilderStub: TronGaslessTransactionsBuilder {
    func buildForGaslessSubmit(
        originalTransaction: BSDKTransaction,
        compensationTransaction: BSDKTransaction,
        signer: TransactionSigner
    ) async throws -> TronGaslessSignedTransactions {
        throw StubError.notNeeded
    }
}

private final class TronTokenFeeLoaderSpy: TronTokenFeeLoader {
    private(set) var receivedRequests: [TronFeeRequestData] = []
    private let fees: [BSDKFee]

    init(fees: [BSDKFee]) {
        self.fees = fees
    }

    func getFee(request: TronFeeRequestData) async throws -> [BSDKFee] {
        receivedRequests.append(request)
        return fees
    }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { throw StubError.notNeeded }
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] { throw StubError.notNeeded }

    func supports(_ input: TokenFeeProviderInputData) -> Bool {
        supportsTronFeeInput(input)
    }

    func loadFees(_ input: TokenFeeProviderInputData, feeBlockchain: Blockchain) async throws -> [BSDKFee] {
        try await loadTronFees(input, feeBlockchain: feeBlockchain)
    }
}

private final class TronGaslessFeeLoaderMock: TokenFeeLoader {
    private(set) var loadedInputs: [TokenFeeProviderInputData] = []
    private let fees: [BSDKFee]
    private let isDEXEnabled: Bool

    init(fees: [BSDKFee], isDEXEnabled: Bool) {
        self.fees = fees
        self.isDEXEnabled = isDEXEnabled
    }

    var rejectsBridgeCoinFee: Bool { true }

    func supports(_ input: TokenFeeProviderInputData) -> Bool {
        switch input {
        case .common, .cex:
            return true
        case .dex(.tron):
            return isDEXEnabled
        case .approve(_, _, let spender, _, _):
            return isDEXEnabled && spender != nil
        case .dex(.ethereum), .dex(.ethereumEstimate), .dex(.solana), .dex(.bitcoinPsbt), .approveWithSwap:
            return false
        }
    }

    func loadFees(_ input: TokenFeeProviderInputData, feeBlockchain _: Blockchain) async throws -> [BSDKFee] {
        guard supports(input) else {
            throw TokenFeeLoaderError.tokenFeeLoaderNotFound
        }

        loadedInputs.append(input)
        return fees
    }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { throw StubError.notNeeded }
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] { throw StubError.notNeeded }
}

private struct NonTronTokenFeeLoaderStub: TokenFeeLoading {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { throw StubError.notNeeded }
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] { throw StubError.notNeeded }
}

private final class TronGaslessNetworkManagerStub: GaslessTransactionsNetworkManager {
    private(set) var estimateRequests: [GaslessTransactionsDTO.Request.TronEstimate] = []

    let cachedFeeRecipientAddress: String? = nil
    var availableFeeTokens: [FeeToken] { [] }
    var availableTronFeeTokens: [TronFeeToken] { [] }
    var currentHost: String { "test" }
    var feeRecipientAddress: String? { nil }

    private let compensationAmountRaw: String

    init(compensationAmountRaw: String) {
        self.compensationAmountRaw = compensationAmountRaw
    }

    func updateAvailableTokens() {}
    func sendGaslessTransaction(_ transaction: GaslessTransaction, executorVersion: GaslessExecutorVersion) async throws -> String { "" }
    func sendGaslessBatchTransaction(_ transaction: GaslessBatchTransaction) async throws -> String { "" }
    func initialize() {}

    func estimateTronGaslessTransaction(
        _ request: TronEstimateRequest,
        userWalletId: UserWalletId
    ) async throws -> TronEstimateResponse {
        estimateRequests.append(request)
        return try Self.makeEstimateResponse(compensationAmountRaw: compensationAmountRaw)
    }

    func submitTronGaslessTransaction(
        _ request: TronSubmitRequest,
        userWalletId: UserWalletId
    ) async throws -> TronSubmitResponse {
        throw StubError.notNeeded
    }

    private static func makeEstimateResponse(compensationAmountRaw: String) throws -> TronEstimateResponse {
        let data = Data(
            """
            {
              "result": {
                "quoteId": "quote",
                "feeRecipient": "TFeeRecipient",
                "compensationToken": "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
                "compensationAmount": "2.5",
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

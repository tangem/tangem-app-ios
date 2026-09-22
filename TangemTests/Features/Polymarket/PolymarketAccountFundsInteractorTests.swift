//
//  PolymarketAccountFundsInteractorTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

// MARK: - Stubs

private struct BridgeServiceStub: PolymarketBridgeService {
    var assets: [PolymarketSupportedAsset] = [.usdcPolygon]
    var assetsError: Error?
    var fundingAddresses = PolymarketBridgeAddresses(addresses: [.evm: fundingAddress])
    var fundingAddressesError: Error?

    let receivedBuilderCodes = OSAllocatedUnfairLock(initialState: [String]())
    let supportedAssetsCallCount = OSAllocatedUnfairLock(initialState: 0)

    func supportedAssets() async throws -> [PolymarketSupportedAsset] {
        supportedAssetsCallCount.withLock { $0 += 1 }

        if let assetsError { throw assetsError }
        return assets
    }

    func fundingAddresses(
        forDepositWallet depositWalletAddress: String,
        builderCode: String
    ) async throws -> PolymarketBridgeAddresses {
        receivedBuilderCodes.withLock { $0.append(builderCode) }

        if let fundingAddressesError { throw fundingAddressesError }
        return fundingAddresses
    }

    func withdrawAddresses(
        forDepositWallet depositWalletAddress: String,
        route: PolymarketWithdrawRoute,
        builderCode: String
    ) async throws -> PolymarketBridgeAddresses {
        receivedBuilderCodes.withLock { $0.append(builderCode) }

        if let fundingAddressesError { throw fundingAddressesError }
        return fundingAddresses
    }
}

private final class ConfigurationServiceSpy: PolymarketConfigurationService {
    static let code = "0x" + String(repeating: "0", count: 63) + "1"

    var callCount: Int { lock.withLock { $0 } }

    private let lock = OSAllocatedUnfairLock(initialState: 0)
    private let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func builderCode() async throws -> String {
        lock.withLock { $0 += 1 }
        if let error { throw error }
        return Self.code
    }
}

private struct DepositWalletServiceStub: PolymarketDepositWalletService {
    var storedAddress: String? = derivedDepositWallet
    var status: PolymarketDepositWalletStatus = .readyToTrade
    var stateError: PolymarketWalletError?

    func depositWalletState(ownerAddress: String?) async throws(PolymarketWalletError) -> PolymarketDepositWallet {
        if let stateError { throw stateError }
        return PolymarketDepositWallet(address: storedAddress, status: status)
    }

    func deployWallet(
        ownerAddress: String,
        depositWalletAddress: String
    ) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus {
        .readyToTrade
    }

    func submitApprovals(_ batch: PolymarketRelayedBatch) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus {
        .readyToTrade
    }
}

private struct OwnerAddressProviderStub: PolymarketOwnerAddressProviding {
    var address: String? = ownerAddress

    func getOwnerAddress() -> String? {
        address
    }

    func deriveOwnerAddress() async throws(PolymarketDerivationError) -> String {
        guard let address else { throw .missingWallet }
        return address
    }
}

private final class FirstAttemptFailsBridgeStub: PolymarketBridgeService {
    private let attempts = OSAllocatedUnfairLock(initialState: 0)

    func supportedAssets() async throws -> [PolymarketSupportedAsset] {
        let attempt = attempts.withLock { count -> Int in
            count += 1
            return count
        }

        guard attempt > 1 else { throw StubError.offline }

        return [.usdcPolygon]
    }

    func fundingAddresses(
        forDepositWallet depositWalletAddress: String,
        builderCode: String
    ) async throws -> PolymarketBridgeAddresses {
        PolymarketBridgeAddresses(addresses: [.evm: fundingAddress])
    }

    func withdrawAddresses(
        forDepositWallet depositWalletAddress: String,
        route: PolymarketWithdrawRoute,
        builderCode: String
    ) async throws -> PolymarketBridgeAddresses {
        PolymarketBridgeAddresses(addresses: [.evm: fundingAddress])
    }
}

private enum StubError: Error {
    case offline
}

// MARK: - Fixtures

private extension PolymarketSupportedAsset {
    static func make(
        chainId: String,
        symbol: String,
        address: String,
        minimum: Decimal = 2
    ) -> PolymarketSupportedAsset {
        PolymarketSupportedAsset(
            chainId: chainId,
            chainName: "Chain \(chainId)",
            family: .evm,
            token: Token(name: symbol, symbol: symbol, address: address, decimalCount: 6),
            minCheckoutUSD: minimum
        )
    }

    static let usdcPolygon = make(
        chainId: "137",
        symbol: "USDC",
        address: PolymarketUtilities.usdcContractAddress,
        minimum: 2
    )
}

private let ownerAddress = "0x1111111111111111111111111111111111111111"
private let fundingAddress = "0x2222222222222222222222222222222222222222"
private let bitcoinFundingAddress = "bc1qfundingaddressplaceholder22222222222222"
private let derivedDepositWallet = try! PolymarketDepositWalletDeriver.derive(ownerAddress: ownerAddress)

private func makeInteractor(
    bridge: any PolymarketBridgeService = BridgeServiceStub(),
    configuration: ConfigurationServiceSpy = ConfigurationServiceSpy(),
    walletService: DepositWalletServiceStub = DepositWalletServiceStub(),
    ownerAddressProvider: OwnerAddressProviderStub = OwnerAddressProviderStub()
) -> PolymarketAccountFundsInteractor {
    PolymarketAccountFundsInteractor(
        bridgeService: bridge,
        configurationService: configuration,
        walletService: walletService,
        ownerAddressProvider: ownerAddressProvider
    )
}

// MARK: - Asset lookup

@Suite("Polymarket add funds asset lookup")
struct PolymarketAddFundsAssetLookupTests {
    @Test("USDC on Polygon is matched by chain and contract, not by symbol")
    func matchesByContract() {
        let lookalike = PolymarketSupportedAsset.make(
            chainId: "137",
            symbol: "USDC",
            address: "0x0000000000000000000000000000000000000001"
        )

        #expect(PolymarketUtilities.usdcOnPolygon(in: [lookalike]) == nil)
        #expect(PolymarketUtilities.usdcOnPolygon(in: [lookalike, .usdcPolygon]) == .usdcPolygon)
    }

    @Test("The same contract on another chain is not a match")
    func rejectsOtherChains() {
        let usdcBase = PolymarketSupportedAsset.make(
            chainId: "8453",
            symbol: "USDC",
            address: PolymarketUtilities.usdcContractAddress
        )

        #expect(PolymarketUtilities.usdcOnPolygon(in: [usdcBase]) == nil)
    }

    @Test("The contract is matched regardless of address casing")
    func ignoresAddressCasing() {
        let checksummed = PolymarketSupportedAsset.make(
            chainId: "137",
            symbol: "USDC",
            address: PolymarketUtilities.usdcContractAddress.uppercased()
        )

        #expect(PolymarketUtilities.usdcOnPolygon(in: [checksummed]) != nil)
    }

    @Test("An empty list has nothing to match")
    func emptyList() {
        #expect(PolymarketUtilities.usdcOnPolygon(in: []) == nil)
    }
}

// MARK: - Preparation

@Suite("Polymarket add funds preparation")
struct PolymarketAddFundsPreparationTests {
    @Test("Add funds is not offered until the bridge has answered")
    func startsLoading() {
        #expect(makeInteractor().state == .loading)
    }

    @Test("Add funds becomes available once the bridge confirms it accepts USDC on Polygon")
    func availableWhenAccepted() async {
        let interactor = makeInteractor()

        await interactor.prepare()

        guard let target = interactor.state.depositTarget else {
            Issue.record("Expected a funding target, got \(interactor.state)")
            return
        }

        #expect(target.asset == .usdcPolygon)
        #expect(target.asset.minCheckoutUSD == 2)
        #expect(target.fundingAddress == fundingAddress)
    }

    @Test("A bridge that does not list USDC on Polygon withholds the deposit without blocking a withdrawal")
    func depositWithheldWhenNotAccepted() async {
        let other = PolymarketSupportedAsset.make(
            chainId: "8453",
            symbol: "USDC",
            address: PolymarketUtilities.usdcContractAddress
        )

        let interactor = makeInteractor(bridge: BridgeServiceStub(assets: [other]))

        await interactor.prepare()

        #expect(interactor.state.depositTarget == nil)
        #expect(interactor.state.depositWalletAddress == derivedDepositWallet)
    }

    @Test("A failing bridge withholds the deposit without blocking a withdrawal")
    func depositWithheldWhenBridgeFails() async {
        let interactor = makeInteractor(bridge: BridgeServiceStub(assetsError: StubError.offline))

        await interactor.prepare()

        #expect(interactor.state.depositTarget == nil)
        #expect(interactor.state.depositWalletAddress == derivedDepositWallet)
    }

    @Test("Without an owner key there is nothing to derive a deposit wallet from")
    func unavailableWithoutOwnerKey() async {
        let interactor = makeInteractor(ownerAddressProvider: OwnerAddressProviderStub(address: nil))

        await interactor.prepare()

        #expect(interactor.state == .unavailable)
    }

    @Test("The builder code is fetched on entry so funding does not pay for it later")
    func fetchesTheBuilderCodeOnEntry() async {
        let configuration = ConfigurationServiceSpy()
        let interactor = makeInteractor(configuration: configuration)

        await interactor.prepare()

        #expect(configuration.callCount == 1)
    }

    @Test("The code the configuration handed over is the one the bridge is asked with, so attribution cannot be lost")
    func builderCodeReachesTheBridge() async {
        let bridge = BridgeServiceStub()
        let interactor = makeInteractor(bridge: bridge)

        await interactor.prepare()

        #expect(bridge.receivedBuilderCodes.withLock { $0 } == [ConfigurationServiceSpy.code])
    }

    @Test("Without a builder code both flows are withheld, since the bridge would credit an unattributed deposit")
    func builderCodeFailureBlocksBothFlows() async {
        let configuration = ConfigurationServiceSpy(error: StubError.offline)
        let interactor = makeInteractor(configuration: configuration)

        await interactor.prepare()

        #expect(interactor.state == .unavailable)
        #expect(interactor.state.depositWalletAddress == nil)
    }

    @Test("The bridge is not asked anything until the builder code is in hand, so the listing cannot overtake the configuration")
    func theBridgeIsSilentUntilTheBuilderCodeArrives() async {
        let bridge = BridgeServiceStub()
        let interactor = makeInteractor(
            bridge: bridge,
            configuration: ConfigurationServiceSpy(error: StubError.offline)
        )

        await interactor.prepare()

        #expect(bridge.supportedAssetsCallCount.withLock { $0 } == 0)
        #expect(bridge.receivedBuilderCodes.withLock { $0 }.isEmpty)
    }

    @Test("Preparing the same interactor again recovers the deposit target, so a pull-to-refresh is a real retry")
    func retryRecoversTheDepositTarget() async {
        let interactor = makeInteractor(bridge: FirstAttemptFailsBridgeStub())

        await interactor.prepare()
        #expect(interactor.state.depositTarget == nil)

        await interactor.prepare()

        #expect(interactor.state.depositTarget != nil)
    }

    @Test("Preparation hands its outcome back, so the caller does not have to read the state to learn it")
    func prepareReturnsTheOutcomeItStored() async {
        let available = makeInteractor()
        let unavailable = makeInteractor(configuration: ConfigurationServiceSpy(error: StubError.offline))

        let availableOutcome = await available.prepare()
        let unavailableOutcome = await unavailable.prepare()

        #expect(availableOutcome == available.state)
        #expect(availableOutcome.depositTarget != nil)
        #expect(unavailableOutcome == .unavailable)
    }
}

// MARK: - The deposit wallet gate

@Suite("Polymarket deposit wallet verification")
struct PolymarketAddFundsDepositWalletTests {
    @Test("The bridge is asked for the address the backend agrees on")
    func usesTheVerifiedAddress() async {
        let interactor = makeInteractor(walletService: DepositWalletServiceStub(storedAddress: derivedDepositWallet))

        await interactor.prepare()

        #expect(interactor.state.depositTarget != nil)
    }

    @Test("A backend record that disagrees with the derivation blocks funding instead of depositing elsewhere")
    func unavailableOnAddressMismatch() async {
        let mismatched = DepositWalletServiceStub(storedAddress: "0xdeadbeef00000000000000000000000000000000")
        let interactor = makeInteractor(walletService: mismatched)

        await interactor.prepare()

        #expect(interactor.state == .unavailable)
    }

    @Test("A backend with no record blocks funding instead of crediting a wallet it does not know")
    func unavailableWhenTheBackendHasNoRecord() async {
        let unknown = DepositWalletServiceStub(storedAddress: nil, status: .notCreated)
        let interactor = makeInteractor(walletService: unknown)

        await interactor.prepare()

        #expect(interactor.state == .unavailable)
    }

    @Test("A deposit wallet that is not ready to trade blocks funding until the backend deploys it")
    func unavailableUntilTheWalletIsReadyToTrade() async {
        let interactor = makeInteractor(walletService: DepositWalletServiceStub(status: .approvalsInProgress))

        await interactor.prepare()

        #expect(interactor.state == .unavailable)
    }

    @Test("An unreachable backend leaves add funds unavailable rather than funding unverified")
    func unavailableWhenTheBackendFails() async {
        let interactor = makeInteractor(walletService: DepositWalletServiceStub(stateError: .unauthorized))

        await interactor.prepare()

        #expect(interactor.state == .unavailable)
    }
}

// MARK: - Funding address

@Suite("Polymarket funding address")
struct PolymarketAddFundsFundingAddressTests {
    @Test("The address handed to the user is the one for the matched asset's chain family")
    func usesTheAssetsFamily() async {
        let bridge = BridgeServiceStub(
            fundingAddresses: PolymarketBridgeAddresses(addresses: [.evm: fundingAddress, .btc: bitcoinFundingAddress])
        )

        let interactor = makeInteractor(bridge: bridge)
        await interactor.prepare()

        #expect(interactor.state.depositTarget?.fundingAddress == fundingAddress)
    }

    @Test("A bridge answer without an address for that family withholds the deposit alone")
    func depositWithheldWithoutAnAddressForThatFamily() async {
        let bridge = BridgeServiceStub(
            fundingAddresses: PolymarketBridgeAddresses(addresses: [.btc: bitcoinFundingAddress])
        )

        let interactor = makeInteractor(bridge: bridge)
        await interactor.prepare()

        #expect(interactor.state.depositTarget == nil)
        #expect(interactor.state.depositWalletAddress == derivedDepositWallet)
    }

    @Test("A funding address that cannot be fetched withholds the deposit alone")
    func depositWithheldWhenTheFundingAddressFails() async {
        let interactor = makeInteractor(bridge: BridgeServiceStub(fundingAddressesError: StubError.offline))

        await interactor.prepare()

        #expect(interactor.state.depositTarget == nil)
        #expect(interactor.state.depositWalletAddress == derivedDepositWallet)
    }

    @Test("The funding address is fetched on entry so opening the receive screen costs no request")
    func fundingAddressIsFetchedOnPreparation() async {
        let interactor = makeInteractor()

        #expect(interactor.state.depositTarget == nil)

        await interactor.prepare()

        #expect(interactor.state.depositTarget != nil)
    }
}

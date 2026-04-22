//
//  BaseWalletManagerTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
@testable import BlockchainSdk
import TangemSdk
import Testing

// MARK: - Token Management

struct BaseWalletManagerTokenTests {
    private let sut: BaseWalletManager

    init() {
        sut = MockSingleAddressWalletManager(wallet: .stub())
    }

    @Test
    func addTokenAppendsToCardTokens() {
        let token = Token.stub(name: "USDT", symbol: "USDT", contractAddress: "0xAAA")

        sut.addToken(token)

        #expect(sut.cardTokens == [token])
    }

    @Test
    func addDuplicateTokenDoesNotDuplicate() {
        let token = Token.stub(name: "USDT", symbol: "USDT", contractAddress: "0xAAA")

        sut.addToken(token)
        sut.addToken(token)

        #expect(sut.cardTokens.count == 1)
    }

    @Test
    func removeTokenRemovesFromCardTokens() {
        let token = Token.stub(name: "USDT", symbol: "USDT", contractAddress: "0xAAA")

        sut.addToken(token)
        sut.removeToken(token)

        #expect(sut.cardTokens.isEmpty)
    }

    @Test
    func addMultipleTokensMaintainsOrder() {
        let tokenA = Token.stub(name: "USDT", symbol: "USDT", contractAddress: "0xAAA")
        let tokenB = Token.stub(name: "USDC", symbol: "USDC", contractAddress: "0xBBB")

        sut.addToken(tokenA)
        sut.addToken(tokenB)

        #expect(sut.cardTokens == [tokenA, tokenB])
    }
}

// MARK: - WalletProvider

struct BaseWalletManagerWalletProviderTests {
    @Test
    func walletPublisherEmitsInitialValue() {
        let wallet = Wallet.stub()
        let sut = MockSingleAddressWalletManager(wallet: wallet)
        var received: [Wallet] = []

        let cancellable = sut.walletPublisher.sink { received.append($0) }

        #expect(received.count == 1)
        #expect(received.first?.address == wallet.address)
        _ = cancellable
    }

    @Test
    func walletPublisherEmitsOnChange() {
        let sut = MockSingleAddressWalletManager(wallet: .stub(address: "addr1"))
        var received: [Wallet] = []

        let cancellable = sut.walletPublisher.sink { received.append($0) }

        sut.wallet = .stub(address: "addr2")

        #expect(received.count == 2)
        #expect(received.last?.address == "addr2")
        _ = cancellable
    }
}

// MARK: - WalletManagerUpdater (state transitions)

struct BaseWalletManagerUpdaterTests {
    @Test
    func initialStateIsInitial() {
        let sut = MockSingleAddressWalletManager(wallet: .stub())

        #expect(sut.state.isInitial)
    }

    @Test
    func updateTransitionsToLoadedOnSuccess() async {
        let sut = MockSingleAddressWalletManager(wallet: .stub())

        await sut.update()

        #expect(sut.state.isLoaded)
        #expect(sut.updateCalledWithAddress == "0xDefaultAddress")
    }

    @Test
    func updateTransitionsToFailedOnError() async {
        let sut = MockSingleAddressWalletManager(wallet: .stub())
        sut.errorToThrow = TestError.updateFailed

        await sut.update()

        #expect(sut.state.isFailed)
    }

    @Test
    func setNeedsUpdateAllowsImmediateReupdate() async {
        let sut = MockSingleAddressWalletManager(wallet: .stub())

        await sut.update()
        #expect(sut.updateCallCount == 1)

        // Second update should be throttled
        await sut.update()
        #expect(sut.updateCallCount == 1)

        // After setNeedsUpdate, it should update again
        sut.setNeedsUpdate()
        await sut.update()
        #expect(sut.updateCallCount == 2)
    }

    @Test
    func statePublisherEmitsTransitions() async {
        let sut = MockSingleAddressWalletManager(wallet: .stub())
        var states: [WalletManagerState] = []

        let cancellable = sut.statePublisher.sink { states.append($0) }

        await sut.update()

        // initial (from subscribe) -> loading -> loaded
        #expect(states.count == 3)
        #expect(states[0].isInitial)
        #expect(states[1].isLoading)
        #expect(states[2].isLoaded)
        _ = cancellable
    }
}

// MARK: - startUpdating dispatch (single address / multi address)

struct BaseWalletManagerDispatchTests {
    @Test
    func singleAddressManagerReceivesDefaultAddress() async {
        let sut = MockSingleAddressWalletManager(wallet: .stub(address: "0xABC"))

        await sut.update()

        #expect(sut.updateCalledWithAddress == "0xABC")
    }

    @Test
    func multiAddressManagerReceivesAllAddresses() async {
        let wallet = Wallet.stub(address: "default_addr", legacyAddress: "legacy_addr")
        let sut = MockMultiAddressWalletManager(wallet: wallet)

        await sut.update()

        #expect(sut.updateCalledWithAddresses?.map(\.value) == ["default_addr", "legacy_addr"])
    }

    @Test
    func singleAddressManagerWithLegacyIgnoresLegacy() async {
        let wallet = Wallet.stub(address: "default_addr", legacyAddress: "legacy_addr")
        let sut = MockSingleAddressWalletManager(wallet: wallet)

        await sut.update()

        #expect(sut.updateCalledWithAddress == "default_addr")
    }

    @Test
    func multiAddressManagerWithSingleAddressWrapsInArray() async {
        let sut = MockMultiAddressOnlyWalletManager(wallet: .stub(address: "only_addr"))

        await sut.update()

        #expect(sut.updateCalledWithAddresses?.map(\.value) == ["only_addr"])
    }

    @Test
    func xpubManagerReceivesGeneratedXPUB() async throws {
        let wallet = try Wallet.xpubStub()
        let sut = MockXPUBWalletManager(wallet: wallet)

        await sut.update()

        #expect(sut.updateCalledWithXpub != nil)
        #expect(sut.state.isLoaded)
    }

    @Test
    func managerWithoutUpdaterConformanceFailsWithError() async {
        let sut = MockNoUpdaterWalletManager(wallet: .stub())

        await sut.update()

        #expect(sut.state.isFailed)
    }
}

// MARK: - Test Helpers

private enum TestError: Error {
    case updateFailed
}

// MARK: - Mock: Single Address

private final class MockSingleAddressWalletManager: BaseWalletManager, BaseWalletManagerUpdater {
    var updateCalledWithAddress: String?
    var updateCallCount = 0
    var errorToThrow: Error?

    func updateWalletManager(address: String) async throws {
        if let errorToThrow {
            throw errorToThrow
        }
        updateCallCount += 1
        updateCalledWithAddress = address
    }
}

// MARK: - Mock: Multi Address

private final class MockMultiAddressWalletManager: BaseWalletManager, BaseWalletManagerUpdater, MultiAddressesWalletManagerUpdater {
    var updateCalledWithAddresses: [any Address]?

    func updateWalletManager(addresses: [any Address]) async throws {
        updateCalledWithAddresses = addresses
    }
}

// MARK: - Mock: Multi Address Only (no BaseWalletManagerUpdater)

private final class MockMultiAddressOnlyWalletManager: BaseWalletManager, MultiAddressesWalletManagerUpdater {
    var updateCalledWithAddresses: [any Address]?

    func updateWalletManager(addresses: [any Address]) async throws {
        updateCalledWithAddresses = addresses
    }
}

// MARK: - Mock: XPUB

private final class MockXPUBWalletManager: BaseWalletManager, BaseWalletManagerUpdater, XPUBWalletManagerUpdater {
    var updateCalledWithXpub: String?

    func updateWalletManager(address _: String) async throws {}

    func updateWalletManager(xpub: String) async throws {
        updateCalledWithXpub = xpub
    }
}

// MARK: - Mock: No Updater

private final class MockNoUpdaterWalletManager: BaseWalletManager {}

// MARK: - Stubs

private extension Wallet {
    static func stub(
        blockchain: Blockchain = .ethereum(testnet: false),
        address: String = "0xDefaultAddress",
        legacyAddress: String? = nil
    ) -> Wallet {
        Wallet(
            blockchain: blockchain,
            publicKey: .empty,
            addressesProvider: CommonAddressesProvider(
                defaultAddress: PlainAddress(value: address, type: .default),
                legacyAddress: legacyAddress.map { PlainAddress(value: $0, type: .legacy) }
            )
        )
    }

    /// Creates a wallet with `.xpub` derivation type using BTC mainnet test vectors
    static func xpubStub() throws -> Wallet {
        let xpubKey = Wallet.PublicKey.XPUBKey(
            child: .init(
                path: try DerivationPath(rawPath: "m/44'/0'/0'/0"),
                extendedPublicKey: ExtendedPublicKey(
                    publicKey: Data(hexString: "03E4528B3940E1BF7502A045067D1822F859FE2ED336B39F0BFD46A8CB38BD3E4B"),
                    chainCode: Data(hexString: "2C2DB3FC7AD8427443550F1F1003C0BA754D364D84998067D0B04202FDE3AD38")
                )
            ),
            parent: .init(
                path: try DerivationPath(rawPath: "m/44'/0'/0'"),
                extendedPublicKey: ExtendedPublicKey(
                    publicKey: Data(hexString: "02FB16DF58DF3C8FDB128CEE3159EF552ED0DDF77451D401C74CD8B1F768246E4C"),
                    chainCode: Data(hexString: "F2FAA12902156F4F3054384CFE11DBB3DA57DCB8F0DACB39DD5632F871F20A83")
                )
            )
        )

        let plainKey = Wallet.PublicKey.HDKey(
            path: try DerivationPath(rawPath: "m/44'/0'/0'/0/0"),
            extendedPublicKey: ExtendedPublicKey(
                publicKey: Data(hexString: "03E4528B3940E1BF7502A045067D1822F859FE2ED336B39F0BFD46A8CB38BD3E4B"),
                chainCode: Data(hexString: "2C2DB3FC7AD8427443550F1F1003C0BA754D364D84998067D0B04202FDE3AD38")
            )
        )

        let publicKey = Wallet.PublicKey(
            seedKey: Data(hexString: "03E4528B3940E1BF7502A045067D1822F859FE2ED336B39F0BFD46A8CB38BD3E4B"),
            derivationType: .xpub(plain: plainKey, xpub: xpubKey)
        )

        return Wallet(
            blockchain: .bitcoin(testnet: false),
            publicKey: publicKey,
            addressesProvider: CommonAddressesProvider(
                defaultAddress: PlainAddress(value: "1BitcoinAddr", type: .default)
            )
        )
    }
}

private extension Token {
    static func stub(
        name: String = "Token",
        symbol: String = "TKN",
        contractAddress: String = "0x0"
    ) -> Token {
        Token(name: name, symbol: symbol, contractAddress: contractAddress, decimalCount: 18)
    }
}

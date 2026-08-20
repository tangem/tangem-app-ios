//
//  ExpressAvailabilityProviderFailureTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

@Suite("CommonExpressAvailabilityProvider assets failure")
struct ExpressAvailabilityProviderFailureTests {
    typealias SUT = CommonExpressAvailabilityProvider

    private let cachedToken: TokenItem = .blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))
    private let unknownToken: TokenItem = .token(
        Token(name: "Unknown", symbol: "UNKNWN", contractAddress: "0xdeadbeef", decimalCount: 18),
        BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)
    )

    @Test("Failed assets request keeps the loaded availability instead of reporting a failure")
    func failureWithCacheKeepsAvailability() async throws {
        let file = TestFile()
        defer { file.remove() }

        let apiProvider = ExpressAPIProviderStub()
        apiProvider.assetsHandler = { [cachedToken] _ in
            [ExpressAsset(currency: cachedToken.expressCurrency.asCurrency, isExchangeable: true, isOnrampable: true)]
        }

        let sut = SUT(storage: CachesDirectoryStorage(file: file), apiProviderFactory: { _ in apiProvider })

        sut.updateExpressAvailability(for: [cachedToken], forceReload: false, userWalletId: Constants.userWalletId)
        let loadedState = try await sut.resolvedState()
        try #require(loadedState.isUpdated)
        #expect(sut.swapState(for: cachedToken) == .available)

        apiProvider.assetsHandler = { _ in throw TestError.rejectedBatch }

        sut.updateExpressAvailability(for: [unknownToken], forceReload: false, userWalletId: Constants.userWalletId)
        let state = try await sut.resolvedState()

        #expect(state.isUpdated)
        #expect(sut.swapState(for: cachedToken) == .available)
    }

    @Test("Failed assets request reports a failure when nothing was ever loaded")
    func failureWithoutCacheReportsFailure() async throws {
        let file = TestFile()
        defer { file.remove() }

        let apiProvider = ExpressAPIProviderStub()
        apiProvider.assetsHandler = { _ in throw TestError.rejectedBatch }

        let sut = SUT(storage: CachesDirectoryStorage(file: file), apiProviderFactory: { _ in apiProvider })

        sut.updateExpressAvailability(for: [cachedToken], forceReload: false, userWalletId: Constants.userWalletId)
        let state = try await sut.resolvedState()

        #expect(!state.isUpdated)
        #expect(sut.swapState(for: cachedToken) == .notLoaded)
    }
}

// MARK: - Helpers

private extension ExpressAvailabilityProvider {
    /// The loading queue is debounced, so the resolved state arrives asynchronously after `.updating`.
    func resolvedState() async throws -> ExpressAvailabilityUpdateState {
        try await expressAvailabilityUpdateState
            .drop { $0.isUpdating }
            .setFailureType(to: Error.self)
            .timeout(.seconds(5), scheduler: DispatchQueue.main, customError: { TestError.stateNotResolved })
            .async()
    }
}

private extension ExpressAvailabilityUpdateState {
    var isUpdating: Bool {
        if case .updating = self { return true }
        return false
    }

    var isUpdated: Bool {
        if case .updated = self { return true }
        return false
    }
}

private struct TestFile: CachesDirectoryStorage.File {
    let name = "express_availability_provider_unit_test_\(UUID().uuidString)"

    var url: URL {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
            .appendingPathExtension("json")
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}

private enum TestError: Error {
    case rejectedBatch
    case stateNotResolved
}

private enum Constants {
    static let userWalletId = "unit_test_user_wallet_id"
}

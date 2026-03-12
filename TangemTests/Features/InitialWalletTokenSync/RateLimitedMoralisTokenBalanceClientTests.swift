//
//  RateLimitedMoralisTokenBalanceClientTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

// MARK: - RateLimitedMoralisTokenBalanceClient Tests

struct RateLimitedMoralisTokenBalanceClientTests {
    @Test
    func succeedsOnFirstAttempt() async throws {
        let mock = MockMoralisTokenBalanceClient(results: [
            .success([.stub]),
        ])
        let sut = makeSUT(client: mock)

        let result = try await sut.getTokenBalances(network: .ethereum(testnet: false), address: "0xABC")

        #expect(result == [.stub])
        #expect(await mock.callCount == 1)
    }

    @Test
    func retriesOnceOn429ThenSucceeds() async throws {
        let mock = MockMoralisTokenBalanceClient(results: [
            .failure(MoralisTokenBalanceError.rateLimited),
            .success([.stub]),
        ])
        let sut = makeSUT(client: mock)

        let result = try await sut.getTokenBalances(network: .ethereum(testnet: false), address: "0xABC")

        #expect(result == [.stub])
        #expect(await mock.callCount == 2)
    }

    @Test
    func failsAfterSecond429() async throws {
        let mock = MockMoralisTokenBalanceClient(results: [
            .failure(MoralisTokenBalanceError.rateLimited),
            .failure(MoralisTokenBalanceError.rateLimited),
        ])
        let sut = makeSUT(client: mock)

        await #expect(throws: MoralisTokenBalanceError.self) {
            _ = try await sut.getTokenBalances(network: .ethereum(testnet: false), address: "0xABC")
        }

        #expect(await mock.callCount == 2)
    }

    @Test
    func doesNotRetryOnNonRateLimitError() async throws {
        let underlyingError = NSError(domain: "test", code: -1)
        let mock = MockMoralisTokenBalanceClient(results: [
            .failure(MoralisTokenBalanceError.network(underlyingError)),
        ])
        let sut = makeSUT(client: mock)

        await #expect(throws: MoralisTokenBalanceError.self) {
            _ = try await sut.getTokenBalances(network: .ethereum(testnet: false), address: "0xABC")
        }

        #expect(await mock.callCount == 1)
    }

    @Test
    func preservesBatchOrder() async throws {
        let addresses = ["0xA", "0xB", "0xC"]
        let mock = MockMoralisTokenBalanceClient(handler: { _, address in
            [MoralisTokenBalance(
                contractAddress: address,
                symbol: "T",
                name: "Token",
                decimals: 18,
                amount: 0,
                isNativeToken: false
            )]
        })
        let sut = makeSUT(client: mock)

        var results: [[MoralisTokenBalance]] = []
        for address in addresses {
            let balances = try await sut.getTokenBalances(network: .ethereum(testnet: false), address: address)
            results.append(balances)
        }

        let returnedAddresses = results.map { $0.first!.contractAddress! }
        #expect(returnedAddresses == addresses)
    }

    // MARK: - Helpers

    private func makeSUT(client: MoralisTokenBalanceClient) -> RateLimitedMoralisTokenBalanceClient {
        let queue = MoralisRateLimitedRequestQueue(maxConcurrentRequests: 3)
        return RateLimitedMoralisTokenBalanceClient(client: client, queue: queue, retryBackoff: .zero)
    }
}

// MARK: - Mock

private actor MockMoralisTokenBalanceClient: MoralisTokenBalanceClient {
    private var results: [Result<[MoralisTokenBalance], Error>]
    private let handler: ((Blockchain, String) -> [MoralisTokenBalance])?
    fileprivate var callCount = 0

    init(results: [Result<[MoralisTokenBalance], Error>]) {
        self.results = results
        handler = nil
    }

    init(handler: @escaping (Blockchain, String) -> [MoralisTokenBalance]) {
        results = []
        self.handler = handler
    }

    func getTokenBalances(network: Blockchain, address: String) async throws -> [MoralisTokenBalance] {
        callCount += 1
        let index = callCount - 1

        if let handler {
            return handler(network, address)
        }

        guard index < results.count else {
            throw MoralisTokenBalanceError.network(NSError(domain: "MockExhausted", code: 0))
        }

        return try results[index].get()
    }
}

// MARK: - Stubs

private extension MoralisTokenBalance {
    static let stub = MoralisTokenBalance(
        contractAddress: "0x1234",
        symbol: "TEST",
        name: "Test Token",
        decimals: 18,
        amount: 100,
        isNativeToken: false
    )
}

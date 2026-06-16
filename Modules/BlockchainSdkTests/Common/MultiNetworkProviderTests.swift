//
//  MultiNetworkProviderTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Combine
import Moya
import TangemFoundation
@testable import BlockchainSdk

struct MultiNetworkProviderTests {
    @Test
    func httpStatusCodeErrorSwitchesToNextHost() async throws {
        let provider = MultiNetworkProviderStub(hosts: ["a.example", "b.example"])

        let result = try await provider.providerPublisher { node -> AnyPublisher<String, Error> in
            provider.requestedHosts.append(node.host)

            if node.host == "a.example" {
                return Fail(error: MoyaError.statusCode(Response(statusCode: 429, data: Data())))
                    .eraseToAnyPublisher()
            }

            return Just("ok").setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        .async()

        #expect(result == "ok")
        #expect(provider.requestedHosts == ["a.example", "b.example"])
        #expect(provider.currentProviderIndex == 1)
    }

    @Test
    func terminalErrorFailsWithoutSwitching() async throws {
        let provider = MultiNetworkProviderStub(hosts: ["a.example", "b.example"])
        provider.stopSwitching = { $0 is JSONRPC.APIError }

        await #expect(throws: JSONRPC.APIError.self) {
            try await provider.providerPublisher { node -> AnyPublisher<String, Error> in
                provider.requestedHosts.append(node.host)

                return Fail(error: JSONRPC.APIError(code: 3, message: "execution reverted"))
                    .eraseToAnyPublisher()
            }
            .async()
        }

        #expect(provider.requestedHosts == ["a.example"])
        #expect(provider.currentProviderIndex == 0)
    }

    @Test
    func exhaustingAllHostsReturnsLastErrorAndResetsIndex() async throws {
        let provider = MultiNetworkProviderStub(hosts: ["a.example", "b.example"])

        do {
            _ = try await provider.providerPublisher { node -> AnyPublisher<String, Error> in
                provider.requestedHosts.append(node.host)

                return Fail(error: MoyaError.statusCode(Response(statusCode: 429, data: Data())))
                    .eraseToAnyPublisher()
            }
            .async()

            Issue.record("Expected an error")
        } catch {
            #expect((error as? MultiNetworkProviderError)?.lastRetryHost == "b.example")
        }

        #expect(provider.requestedHosts == ["a.example", "b.example"])
        #expect(provider.currentProviderIndex == 0)
    }

    @Test
    func executionRevertedDetectionMatchesBareAndWrappedErrors() {
        let revert = JSONRPC.APIError(code: 3, message: "execution reverted")
        let rateLimit = JSONRPC.APIError(code: -32005, message: "Too Many Requests")

        #expect(revert.isEVMExecutionReverted)
        #expect(MultiNetworkProviderError(networkError: revert, lastRetryHost: "a.example").isEVMExecutionReverted)
        #expect(!rateLimit.isEVMExecutionReverted)
        #expect(!MoyaError.statusCode(Response(statusCode: 429, data: Data())).isEVMExecutionReverted)
    }

    @Test
    func ethereumServiceStopsOnlyOnContractExecutionErrors() {
        let service = EthereumNetworkService(
            decimals: 18,
            providers: [],
            abiEncoder: WalletCoreABIEncoder(),
            blockchainName: "Ethereum"
        )

        #expect(service.shouldStopSwitching(error: JSONRPC.APIError(code: 3, message: nil)))
        #expect(service.shouldStopSwitching(error: JSONRPC.APIError(code: -32000, message: "Execution Reverted: claim tokens failed")))
        #expect(!service.shouldStopSwitching(error: JSONRPC.APIError(code: -32005, message: "Too Many Requests")))
        #expect(!service.shouldStopSwitching(error: JSONRPC.APIError(code: nil, message: nil)))
        #expect(!service.shouldStopSwitching(error: MoyaError.statusCode(Response(statusCode: 429, data: Data()))))
    }
}

private final class MultiNetworkProviderStub: MultiNetworkProvider {
    final class NodeStub: HostProvider {
        let host: String

        init(host: String) {
            self.host = host
        }
    }

    let providers: [NodeStub]
    var currentProviderIndex = 0
    let blockchainName = "TestChain"

    var requestedHosts: [String] = []
    var stopSwitching: (Error) -> Bool = { _ in false }

    init(hosts: [String]) {
        providers = hosts.map(NodeStub.init)
    }

    func shouldStopSwitching(error: Error) -> Bool {
        stopSwitching(error)
    }
}

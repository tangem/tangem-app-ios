//
//  YieldModuleAddressConsensusTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

@Suite("Yield module address consensus")
struct YieldModuleAddressConsensusTests {
    @Test("A single node response is accepted")
    func acceptsSingleResponse() throws {
        let result = try YieldModuleUtils.resolveConsistentEthereumAddress(from: [
            .failure(TestError()),
            .success(Self.response(for: Self.firstAddress)),
        ])

        #expect(result == Self.firstAddress)
    }

    @Test("Matching node responses are accepted")
    func acceptsMatchingResponses() throws {
        let result = try YieldModuleUtils.resolveConsistentEthereumAddress(from: [
            .success(Self.response(for: Self.firstAddress)),
            .success(Self.response(for: Self.firstAddress.uppercased())),
        ])

        #expect(result == Self.firstAddress)
    }

    @Test("Conflicting node responses fail")
    func rejectsConflictingResponses() {
        do {
            _ = try YieldModuleUtils.resolveConsistentEthereumAddress(from: [
                .success(Self.response(for: Self.firstAddress)),
                .success(Self.response(for: Self.secondAddress)),
            ])
            Issue.record("Expected inconsistent state error")
        } catch YieldModuleError.inconsistentState {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Zero address is ignored")
    func ignoresZeroAddress() throws {
        let result = try YieldModuleUtils.resolveConsistentEthereumAddress(from: [
            .success(Self.zeroAddressResponse),
            .success(Self.response(for: Self.firstAddress)),
        ])

        #expect(result == Self.firstAddress)
    }

    @Test("Only zero addresses produce no contract error")
    func rejectsOnlyZeroAddresses() {
        do {
            _ = try YieldModuleUtils.resolveConsistentEthereumAddress(from: [
                .success(Self.zeroAddressResponse),
                .success(Self.zeroAddressResponse),
            ])
            Issue.record("Expected no Yield contract error")
        } catch YieldModuleError.noYieldContractFound {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private static let firstAddress = "0x1111111111111111111111111111111111111111"
    private static let secondAddress = "0x2222222222222222222222222222222222222222"
    private static let zeroAddressResponse = "0x" + String(repeating: "0", count: 64)

    private static func response(for address: String) -> String {
        "0x" + String(repeating: "0", count: 24) + address.removeHexPrefix()
    }
}

private struct TestError: Error {}

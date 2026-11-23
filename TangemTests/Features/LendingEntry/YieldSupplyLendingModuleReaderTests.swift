//
//  YieldSupplyLendingModuleReaderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk
@testable import Tangem

@Suite("Lending module reader")
struct YieldSupplyLendingModuleReaderTests {
    @Test("A wallet without a yield module reads as no module, so the deposit deploys one")
    func missingModuleIsNoModule() async throws {
        let reader = YieldSupplyLendingModuleReader(service: YieldSupplyServiceStub(yieldContract: .failure(YieldModuleError.noYieldContractFound)))

        let module = try await reader.yieldModule()

        #expect(module == nil)
    }

    @Test("A module read that fails for any other reason is an error, not a missing module, so no second module gets deployed")
    func failedReadIsError() async {
        let reader = YieldSupplyLendingModuleReader(service: YieldSupplyServiceStub(yieldContract: .failure(ReadError())))

        await #expect(throws: ReadError.self) {
            try await reader.yieldModule()
        }
    }

    @Test("A deployed module is returned as is")
    func deployedModule() async throws {
        let reader = YieldSupplyLendingModuleReader(service: YieldSupplyServiceStub(yieldContract: .success("0x00000000000000000000000000000000000000a1")))

        let module = try await reader.yieldModule()

        #expect(module == "0x00000000000000000000000000000000000000a1")
    }
}

// MARK: - Stubs

private struct ReadError: Error {}

private struct YieldSupplyServiceStub: YieldSupplyService {
    let yieldContract: Result<String, Error>

    func isSupported() -> Bool { true }
    func getYieldSupplyContractAddresses() throws -> YieldSupplyContractAddresses { throw ReadError() }
    func getYieldContract() async throws -> String { try yieldContract.get() }
    func storeYieldContract(_ yieldContract: String) async {}
    func storedYieldContract() -> String? { nil }
    func calculateYieldContract() async throws -> String { throw ReadError() }
    func getYieldSupplyStatus(tokenContractAddress: String) async throws -> YieldSupplyStatus { throw ReadError() }
    func getBalance(yieldSupplyStatus: YieldSupplyStatus, token: Token) async throws -> Amount { throw ReadError() }
    func getBalances(address: String, tokens: [Token]) async -> [Token: Result<Amount, Error>] { [:] }
    func allowance(tokenContractAddress: String) async throws -> String { throw ReadError() }
}

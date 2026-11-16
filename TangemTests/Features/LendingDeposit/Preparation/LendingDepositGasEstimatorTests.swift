//
//  LendingDepositGasEstimatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import BlockchainSdk
@testable import Tangem

@Suite("Lending deposit gas estimator", .timeLimit(.minutes(1)))
struct LendingDepositGasEstimatorTests {
    private static let blockchain = BlockchainSdk.Blockchain.ethereum(testnet: false)
    private static let preparation = TransferPreparationCall(destination: "0x2222222222222222222222222222222222222222", value: 0, data: Data([0xCB]))
    private static let deposit = TransferPreparationCall(destination: "0x1111111111111111111111111111111111111111", value: 1, data: Data([0x09]))

    @Test("Simulated gas gets the yield-module margin")
    func simulatedGas() async {
        let sut = makeSUT(result: .success([.estimated("0x30d40"), .estimated("0x493e0")]))

        let gas = await sut.gas(preparation: Self.preparation, deposit: Self.deposit)

        let margin = Int(EthereumFeeParametersConstants.yieldModuleGasLimitIncreasePercent)
        #expect(gas == TransferPreparationGas(preparation: 200_000 + 200_000 * margin / 100, mainCall: 300_000 + 300_000 * margin / 100))
    }

    @Test("Without a usable simulation both transactions get the fallback limit with the yield-module margin", arguments: [false, true])
    func fallbackGas(simulationFails: Bool) async {
        let sut = makeSUT(result: Self.unusableSimulation(fails: simulationFails))

        let gas = await sut.gas(preparation: Self.preparation, deposit: Self.deposit)

        #expect(gas == Self.fallbackGas)
    }

    @Test("Before the module exists a pair without a usable simulation gets no gas, so the deposit can't go to an address with no code", arguments: [false, true])
    func noFallbackForDeployment(simulationFails: Bool) async {
        let sut = makeSUT(simulator: GasSimulatorSpy(result: Self.unusableSimulation(fails: simulationFails)), allowsFallback: false)

        let gas = await sut.gas(preparation: Self.preparation, deposit: Self.deposit)

        #expect(gas == nil)
    }

    @Test("A deposit value finer than a wei isn't simulated as a zero deposit, both transactions get the fallback limit")
    func valueFinerThanWei() async throws {
        let simulator = GasSimulatorSpy(result: .success([.estimated("0x30d40"), .estimated("0x493e0")]))
        let sut = makeSUT(simulator: simulator)
        let deposit = try TransferPreparationCall(destination: Self.deposit.destination, value: #require(Decimal(string: "0.0617283945061728385")), data: Self.deposit.data)

        let gas = await sut.gas(preparation: Self.preparation, deposit: deposit)

        #expect(gas == Self.fallbackGas)
        #expect(simulator.requests.isEmpty)
    }

    @Test("A simulation where either transaction reverts gives no gas, so the deposit can't be sent", arguments: [0, 1])
    func revertedSimulation(revertedIndex: Int) async {
        var simulations: [LendingDepositGasSimulation] = [.estimated("0x30d40"), .estimated("0x493e0")]
        simulations[revertedIndex] = .reverted
        let sut = makeSUT(result: .success(simulations))

        let gas = await sut.gas(preparation: Self.preparation, deposit: Self.deposit)

        #expect(gas == nil)
    }

    @Test("Blockaid's answer for a reverted deposit reads as a revert, not as an unusable response")
    func blockaidRevertResponse() throws {
        let body = #"""
        [{"gas_estimation":{"status":"Success","used":"0x4dc09","estimate":"0x5e629"},"block":"26355766","chain":"ethereum"},
         {"gas_estimation":{"status":"Error","error":"Simulation Error: execution reverted"},"block":"26355766","chain":"ethereum"}]
        """#

        let simulations = try BlockaidLendingDepositGasSimulator.simulations(from: Data(body.utf8))

        #expect(simulations == [.estimated("0x5e629"), .reverted])
    }
}

// MARK: - Helpers

private extension LendingDepositGasEstimatorTests {
    func makeSUT(result: Result<[LendingDepositGasSimulation], Error>) -> LendingDepositGasEstimator {
        makeSUT(simulator: GasSimulatorSpy(result: result))
    }

    func makeSUT(simulator: GasSimulatorSpy, allowsFallback: Bool = true) -> LendingDepositGasEstimator {
        LendingDepositGasEstimator(
            owner: "0x3333333333333333333333333333333333333333",
            blockchain: Self.blockchain,
            simulator: simulator,
            allowsFallback: allowsFallback
        )
    }

    static var fallbackGas: TransferPreparationGas {
        let margin = Int(EthereumFeeParametersConstants.yieldModuleGasLimitIncreasePercent)
        let limit = 500_000 + 500_000 * margin / 100
        return TransferPreparationGas(preparation: limit, mainCall: limit)
    }

    static func unusableSimulation(fails: Bool) -> Result<[LendingDepositGasSimulation], Error> {
        fails ? .failure(ErrorStub()) : .success([.estimated("0x0"), .estimated("0x493e0")])
    }
}

// MARK: - Stubs

private struct ErrorStub: Error {}

private final class GasSimulatorSpy: LendingDepositGasSimulating {
    private let result: Result<[LendingDepositGasSimulation], Error>
    private let recorded = OSAllocatedUnfairLock(initialState: [[BlockaidDTO.TransactionParams]]())

    var requests: [[BlockaidDTO.TransactionParams]] {
        recorded.withLock { $0 }
    }

    init(result: Result<[LendingDepositGasSimulation], Error>) {
        self.result = result
    }

    func simulate(_ transactions: [BlockaidDTO.TransactionParams], on blockchain: BlockchainSdk.Blockchain) async throws -> [LendingDepositGasSimulation] {
        recorded.withLock { $0.append(transactions) }
        return try result.get()
    }
}

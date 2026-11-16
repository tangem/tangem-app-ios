//
//  LendingDepositEntryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Testing
@testable import BlockchainSdk
@testable import Tangem

@Suite("Lending on Aave deposit entry", .timeLimit(.minutes(1)))
struct LendingDepositEntryTests {
    @Test("Each module check row of the PRD leads to its own entry", arguments: Scenario.allCases)
    func moduleCheck(scenario: Scenario) async {
        let entry = await makeSUT(reader: scenario.reader).load()

        #expect(entry == scenario.expected)
    }

    @Test("A withdrawal goes to the module as is when no newer native version is available")
    func withdrawalWithoutUpgrade() async throws {
        let target = try await makeSUT(reader: ReaderStub()).withdrawalTarget()

        #expect(target == LendingWithdrawalTarget(yieldModule: ReaderStub.module, upgradeImplementation: nil))
    }

    @Test("A withdrawal carries the module upgrade when a newer native version is available")
    func withdrawalWithUpgrade() async throws {
        let reader = ReaderStub(upgrade: .success(.upgradeAvailable(targetImplementation: ReaderStub.implementation, targetVersion: .v3)))

        let target = try await makeSUT(reader: reader).withdrawalTarget()

        #expect(target == LendingWithdrawalTarget(yieldModule: ReaderStub.module, upgradeImplementation: ReaderStub.implementation))
    }

    @Test("A deposit with nothing to prepare goes to the module with its upgrade")
    func requestWithoutPreparation() throws {
        let entry = LendingDepositEntry.deposit(yieldModule: ReaderStub.module, upgradeImplementation: ReaderStub.implementation, preparation: nil)

        let request = try #require(makeSUT(reader: ReaderStub()).depositRequest(for: entry))

        #expect(request.yieldModule == ReaderStub.module)
        #expect(request.upgradeImplementation == ReaderStub.implementation)
        #expect(request.preparation == nil)
        #expect(request.isWithUpgrade)
    }

    @Test("A deposit that needs preparing is refused when the preparation can't be built")
    func requestWithoutPreparationFactory() {
        let entry = LendingDepositEntry.deposit(yieldModule: ReaderStub.predictedModule, upgradeImplementation: nil, preparation: .deployModule)

        #expect(makeSUT(reader: ReaderStub()).depositRequest(for: entry) == nil)
        #expect(makeSUT(reader: ReaderStub()).depositRequest(for: .blocked(.failedToLoad)) == nil)
    }

    @Test("A deposit that needs preparing carries the built preparation and counts an upgrade that rides on it", arguments: [nil, ReaderStub.implementation])
    func requestWithPreparation(upgradeImplementation: String?) throws {
        var loader = makeSUT(reader: ReaderStub())
        loader.preparationFactory = PreparationMakerStub()
        let entry = LendingDepositEntry.deposit(
            yieldModule: ReaderStub.module,
            upgradeImplementation: nil,
            preparation: .reactivateToken(upgradeImplementation: upgradeImplementation)
        )

        let request = try #require(loader.depositRequest(for: entry))

        #expect(request.yieldModule == ReaderStub.module)
        #expect(request.upgradeImplementation == nil)
        #expect(request.preparation != nil)
        #expect(request.isWithUpgrade == (upgradeImplementation != nil))
    }

    @Test("A withdrawal from a module that can't take the native call, and can't be upgraded to one, is refused before anything is built")
    func withdrawalFromOldModule() async {
        let statuses: [YieldModuleUpgradeStatus] = [
            .upgradeUnavailable(version: .v2),
            .upToDate(version: .v2),
            .upgradeAvailable(targetImplementation: ReaderStub.implementation, targetVersion: .v2),
        ]

        for status in statuses {
            await #expect(throws: LendingWithdrawalTargetError.unsupportedModule) {
                try await makeSUT(reader: ReaderStub(upgrade: .success(status))).withdrawalTarget()
            }
        }
    }

    @Test("Without a module there is nothing to withdraw from")
    func withdrawalWithoutModule() async throws {
        let target = try await makeSUT(reader: ReaderStub(module: .success(nil))).withdrawalTarget()

        #expect(target == nil)
    }
}

// MARK: - Helpers

private extension LendingDepositEntryTests {
    func makeSUT(reader: ReaderStub) -> LendingDepositEntryLoader {
        LendingDepositEntryLoader(reader: reader)
    }
}

extension LendingDepositEntryTests {
    enum Scenario: String, CaseIterable, CustomTestStringConvertible {
        case moduleReadFails
        case upgradeReadFails
        case wrappedNativeReadFails
        case noModule
        case moduleTooOldWithoutUpgrade
        case upgradeStopsBelowNativeVersion
        case wrappedNativeNotInitialised
        case wrappedNativeInactive
        case wrappedNativeInactiveBeforeUpgrade
        case depositReady
        case depositReadyAfterUpgrade

        var testDescription: String { rawValue }

        fileprivate var reader: ReaderStub {
            switch self {
            case .moduleReadFails:
                ReaderStub(module: .failure(StubError()))
            case .upgradeReadFails:
                ReaderStub(upgrade: .failure(StubError()))
            case .wrappedNativeReadFails:
                ReaderStub(token: .failure(StubError()))
            case .noModule:
                ReaderStub(module: .success(nil))
            case .moduleTooOldWithoutUpgrade:
                ReaderStub(upgrade: .success(.upgradeUnavailable(version: .v2)))
            case .upgradeStopsBelowNativeVersion:
                ReaderStub(upgrade: .success(.upgradeAvailable(targetImplementation: ReaderStub.implementation, targetVersion: .v2)))
            case .wrappedNativeNotInitialised:
                ReaderStub(token: .success(YieldSupplyStatus(initialized: false, active: false, maxNetworkFee: 0)))
            case .wrappedNativeInactive:
                ReaderStub(token: .success(YieldSupplyStatus(initialized: true, active: false, maxNetworkFee: 0)))
            case .wrappedNativeInactiveBeforeUpgrade:
                ReaderStub(
                    upgrade: .success(.upgradeAvailable(targetImplementation: ReaderStub.implementation, targetVersion: .v3)),
                    token: .success(YieldSupplyStatus(initialized: true, active: false, maxNetworkFee: 0))
                )
            case .depositReady:
                ReaderStub()
            case .depositReadyAfterUpgrade:
                ReaderStub(upgrade: .success(.upgradeAvailable(targetImplementation: ReaderStub.implementation, targetVersion: .v3)))
            }
        }

        var expected: LendingDepositEntry {
            switch self {
            case .moduleReadFails, .upgradeReadFails, .wrappedNativeReadFails: .blocked(.failedToLoad)
            case .noModule: .deposit(yieldModule: ReaderStub.predictedModule, upgradeImplementation: nil, preparation: .deployModule)
            case .moduleTooOldWithoutUpgrade, .upgradeStopsBelowNativeVersion: .blocked(.unsupportedModule)
            case .wrappedNativeNotInitialised:
                .deposit(yieldModule: ReaderStub.module, upgradeImplementation: nil, preparation: .initializeToken(upgradeImplementation: nil))
            case .wrappedNativeInactive:
                .deposit(yieldModule: ReaderStub.module, upgradeImplementation: nil, preparation: .reactivateToken(upgradeImplementation: nil))
            case .wrappedNativeInactiveBeforeUpgrade:
                .deposit(
                    yieldModule: ReaderStub.module,
                    upgradeImplementation: nil,
                    preparation: .reactivateToken(upgradeImplementation: ReaderStub.implementation)
                )
            case .depositReady: .deposit(yieldModule: ReaderStub.module, upgradeImplementation: nil, preparation: nil)
            case .depositReadyAfterUpgrade:
                .deposit(yieldModule: ReaderStub.module, upgradeImplementation: ReaderStub.implementation, preparation: nil)
            }
        }
    }
}

// MARK: - Stubs

private struct StubError: Error {}

private struct ReaderStub: LendingModuleReader {
    static let module = "0x00000000000000000000000000000000000000a1"
    static let implementation = "0x00000000000000000000000000000000000000b2"
    static let predictedModule = "0x00000000000000000000000000000000000000c3"

    var module: Result<String?, Error> = .success(ReaderStub.module)
    var upgrade: Result<YieldModuleUpgradeStatus, Error> = .success(.upToDate(version: .v3))
    var token: Result<YieldSupplyStatus, Error> = .success(YieldSupplyStatus(initialized: true, active: true, maxNetworkFee: 0))

    func yieldModule() async throws -> String? {
        try module.get()
    }

    func predictedYieldModule() async throws -> String {
        ReaderStub.predictedModule
    }

    func upgradeStatus(yieldModule: String) async throws -> YieldModuleUpgradeStatus {
        try upgrade.get()
    }

    func liquidityProvider() -> YieldModuleLendingLiquidityProvider? {
        nil
    }

    func factoryAddress() throws -> String {
        ""
    }

    func tokenStatus(wrappedNative: String) async throws -> YieldSupplyStatus {
        try token.get()
    }
}

private struct PreparationMakerStub: LendingDepositPreparationMaking {
    func make(_ preparation: LendingDepositPreparation, yieldModule: String) -> TransferPreparation? {
        PreparationStub()
    }
}

private struct PreparationStub: TransferPreparation {
    func gas(mainCall: TransferPreparationCall) async -> TransferPreparationGas? {
        TransferPreparationGas(preparation: 0, mainCall: 0)
    }

    func send(mainCall: BSDKTransaction, gas: TransferPreparationGas) async throws -> TransactionDispatcherResult {
        TransactionDispatcherResult(hash: "hash", url: nil, signerType: "test", currentHost: "test")
    }
}

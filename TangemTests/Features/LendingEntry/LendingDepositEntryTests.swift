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
            case .depositReady:
                ReaderStub()
            case .depositReadyAfterUpgrade:
                ReaderStub(upgrade: .success(.upgradeAvailable(targetImplementation: ReaderStub.implementation, targetVersion: .v3)))
            }
        }

        var expected: LendingDepositEntry {
            switch self {
            case .moduleReadFails, .upgradeReadFails, .wrappedNativeReadFails: .blocked(.failedToLoad)
            case .noModule: .blocked(.deployModule)
            case .moduleTooOldWithoutUpgrade, .upgradeStopsBelowNativeVersion: .blocked(.unsupportedModule)
            case .wrappedNativeNotInitialised: .blocked(.activateToken(.initialize))
            case .wrappedNativeInactive: .blocked(.activateToken(.reactivate))
            case .depositReady: .deposit(yieldModule: ReaderStub.module, upgradeImplementation: nil)
            case .depositReadyAfterUpgrade: .deposit(yieldModule: ReaderStub.module, upgradeImplementation: ReaderStub.implementation)
            }
        }
    }
}

// MARK: - Stubs

private struct StubError: Error {}

private struct ReaderStub: LendingModuleReader {
    static let module = "0x00000000000000000000000000000000000000a1"
    static let implementation = "0x00000000000000000000000000000000000000b2"

    var module: Result<String?, Error> = .success(ReaderStub.module)
    var upgrade: Result<YieldModuleUpgradeStatus, Error> = .success(.upToDate(version: .v3))
    var token: Result<YieldSupplyStatus, Error> = .success(YieldSupplyStatus(initialized: true, active: true, maxNetworkFee: 0))

    func yieldModule() async throws -> String? {
        try module.get()
    }

    func upgradeStatus(yieldModule: String) async throws -> YieldModuleUpgradeStatus {
        try upgrade.get()
    }

    func tokenStatus(wrappedNative: String) async throws -> YieldSupplyStatus {
        try token.get()
    }
}

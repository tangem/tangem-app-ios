//
//  YieldLendingDepositStateTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Testing
@testable import Tangem

@Suite("YieldLendingDepositState")
struct YieldLendingDepositStateTests {
    typealias SUT = YieldLendingDepositState

    @Test("Module reads in flight show loading")
    func loading() {
        #expect(SUT.make(module: .loading) == .loading)
    }

    @Test("A failed module read offers no deposit")
    func failedRead() {
        #expect(SUT.make(module: .failure(ReadError())) == .failedToLoad)
    }

    @Test("Without a module, a paused factory makes lending temporarily unavailable")
    func noModuleWhileFactoryPaused() {
        #expect(SUT.make(module: .success(.notDeployed(isFactoryPaused: true))) == .temporarilyUnavailable)
    }

    @Test("Without a module, the module is deployed first")
    func noModuleDeploysOne() {
        #expect(SUT.make(module: .success(.notDeployed(isFactoryPaused: false))) == .deployModule)
    }

    @Test("A module that cannot reach the native version blocks lending whatever the token state")
    func unsupportedModule() {
        for token in tokenStates {
            #expect(SUT.make(module: .success(.deployed(nativeSupport: .unavailable, token: token))) == .unsupportedModule)
        }
    }

    @Test("Suspended entry pauses deposits whatever the token state")
    func entrySuspended() {
        for token in tokenStates {
            let module = SUT.Module.deployed(nativeSupport: .supported(isEntrySuspended: true), token: token)

            #expect(SUT.make(module: .success(module)) == .depositsPaused)
        }
    }

    @Test("An uninitialised token is initialised before the deposit", arguments: depositableNativeSupport)
    func uninitialisedToken(nativeSupport: SUT.NativeSupport) {
        let module = SUT.Module.deployed(nativeSupport: nativeSupport, token: .notInitialized)

        #expect(SUT.make(module: .success(module)) == .activateToken(.initialize))
    }

    @Test("A token deactivated by a full withdrawal is reactivated before the deposit", arguments: depositableNativeSupport)
    func inactiveToken(nativeSupport: SUT.NativeSupport) {
        let module = SUT.Module.deployed(nativeSupport: nativeSupport, token: .initialized(activeState: .notActive))

        #expect(SUT.make(module: .success(module)) == .activateToken(.reactivate))
    }

    @Test("An active token on a native-capable module deposits without an upgrade")
    func depositWithoutUpgrade() {
        let module = SUT.Module.deployed(nativeSupport: .supported(isEntrySuspended: false), token: activeToken)

        #expect(SUT.make(module: .success(module)) == .depositAvailable(withUpgrade: false))
    }

    @Test("An active token on an upgradeable older module deposits together with the upgrade")
    func depositWithUpgrade() {
        let module = SUT.Module.deployed(nativeSupport: .afterUpgrade, token: activeToken)

        #expect(SUT.make(module: .success(module)) == .depositAvailable(withUpgrade: true))
    }
}

// MARK: - Fixtures

private extension YieldLendingDepositStateTests {
    static let depositableNativeSupport: [SUT.NativeSupport] = [.supported(isEntrySuspended: false), .afterUpgrade]

    var activeToken: YieldModuleSmartContractState.InitializationState {
        .initialized(activeState: .active(info: .init(balance: nil, maxNetworkFee: BigUInt(1))))
    }

    var tokenStates: [YieldModuleSmartContractState.InitializationState] {
        [.notInitialized, .initialized(activeState: .notActive), activeToken]
    }

    struct ReadError: Error {}
}

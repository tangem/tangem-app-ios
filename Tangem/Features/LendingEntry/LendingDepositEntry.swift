//
//  LendingDepositEntry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum LendingDepositEntry: Equatable {
    case deposit(yieldModule: String, upgradeImplementation: String?, preparation: LendingDepositPreparation?)
    case blocked(YieldLendingDepositState)
}

// MARK: - Loader

struct LendingDepositEntryLoader {
    let reader: LendingModuleReader
    var preparationFactory: LendingDepositPreparationMaking?
    var wrappedNative: String = LendingOnAave.wrappedNativeAddress

    func load() async -> LendingDepositEntry {
        do {
            guard let yieldModule = try await reader.yieldModule() else {
                let predictedModule = try await reader.predictedYieldModule()
                return .deposit(yieldModule: predictedModule, upgradeImplementation: nil, preparation: .deployModule)
            }

            async let upgradeStatus = reader.upgradeStatus(yieldModule: yieldModule)
            async let tokenStatus = reader.tokenStatus(wrappedNative: wrappedNative)
            let (status, token) = try await (upgradeStatus, tokenStatus)
            let support = Self.nativeSupport(for: status)
            let state = YieldLendingDepositState.make(
                module: .success(.deployed(nativeSupport: support.nativeSupport, token: Self.initializationState(of: token)))
            )

            switch state {
            case .depositAvailable:
                return .deposit(yieldModule: yieldModule, upgradeImplementation: support.upgradeImplementation, preparation: nil)
            case .activateToken(.initialize):
                return .deposit(
                    yieldModule: yieldModule,
                    upgradeImplementation: nil,
                    preparation: .initializeToken(upgradeImplementation: support.upgradeImplementation)
                )
            case .activateToken(.reactivate):
                return .deposit(
                    yieldModule: yieldModule,
                    upgradeImplementation: nil,
                    preparation: .reactivateToken(upgradeImplementation: support.upgradeImplementation)
                )
            case .loading, .failedToLoad, .deployModule, .unsupportedModule:
                return .blocked(state)
            }
        } catch {
            return .blocked(.make(module: .failure(error)))
        }
    }

    func depositRequest(for entry: LendingDepositEntry) -> LendingDepositRequest? {
        guard case .deposit(let yieldModule, let upgradeImplementation, let preparation) = entry else {
            return nil
        }

        guard let preparation else {
            return LendingDepositRequest(yieldModule: yieldModule, upgradeImplementation: upgradeImplementation, preparation: nil, isWithUpgrade: upgradeImplementation != nil)
        }

        guard let transferPreparation = preparationFactory?.make(preparation, yieldModule: yieldModule) else {
            return nil
        }

        return LendingDepositRequest(
            yieldModule: yieldModule,
            upgradeImplementation: upgradeImplementation,
            preparation: transferPreparation,
            isWithUpgrade: preparation.upgradeImplementation != nil
        )
    }

    func withdrawalTarget() async throws -> LendingWithdrawalTarget? {
        guard let yieldModule = try await reader.yieldModule() else {
            return nil
        }

        let support = try await Self.nativeSupport(for: reader.upgradeStatus(yieldModule: yieldModule))

        guard support.nativeSupport != .unavailable else {
            throw LendingWithdrawalTargetError.unsupportedModule
        }

        return LendingWithdrawalTarget(yieldModule: yieldModule, upgradeImplementation: support.upgradeImplementation)
    }
}

struct LendingDepositRequest {
    let yieldModule: String
    let upgradeImplementation: String?
    let preparation: TransferPreparation?
    let isWithUpgrade: Bool
}

struct LendingWithdrawalTarget: Equatable {
    let yieldModule: String
    let upgradeImplementation: String?
}

enum LendingWithdrawalTargetError: Error {
    case unsupportedModule
}

// MARK: - Private

private extension LendingDepositEntryLoader {
    static func nativeSupport(
        for status: YieldModuleUpgradeStatus
    ) -> (nativeSupport: YieldLendingDepositState.NativeSupport, upgradeImplementation: String?) {
        if let target = nativeUpgradeTarget(of: status) {
            return (.afterUpgrade, target)
        }

        guard status.supports(LendingOnAave.nativeSupportVersion) else {
            return (.unavailable, nil)
        }

        return (.supported, nil)
    }

    static func nativeUpgradeTarget(of status: YieldModuleUpgradeStatus) -> String? {
        guard case .upgradeAvailable(let target, let targetVersion) = status, targetVersion >= LendingOnAave.nativeSupportVersion else {
            return nil
        }

        return target
    }

    static func initializationState(of status: YieldSupplyStatus) -> YieldModuleSmartContractState.InitializationState {
        switch (status.initialized, status.active) {
        case (false, _):
            return .notInitialized
        case (true, false):
            return .initialized(activeState: .notActive)
        case (true, true):
            return .initialized(activeState: .active(info: .init(balance: nil, maxNetworkFee: status.maxNetworkFee)))
        }
    }
}

// MARK: - Reader

protocol LendingModuleReader {
    func yieldModule() async throws -> String?
    func predictedYieldModule() async throws -> String
    func upgradeStatus(yieldModule: String) async throws -> YieldModuleUpgradeStatus
    func tokenStatus(wrappedNative: String) async throws -> YieldSupplyStatus
    func liquidityProvider() -> YieldModuleLendingLiquidityProvider?
    func factoryAddress() throws -> String
}

struct YieldSupplyLendingModuleReader: LendingModuleReader {
    let service: YieldSupplyService

    func yieldModule() async throws -> String? {
        do {
            return try await service.getYieldContract()
        } catch YieldModuleError.noYieldContractFound {
            return nil
        }
    }

    func predictedYieldModule() async throws -> String {
        try await service.calculateYieldContract()
    }

    func upgradeStatus(yieldModule: String) async throws -> YieldModuleUpgradeStatus {
        guard let resolver = service.makeVersionResolver() else {
            return .upgradeUnavailable(version: nil)
        }

        return try await resolver.resolveStatus(moduleAddress: yieldModule)
    }

    func tokenStatus(wrappedNative: String) async throws -> YieldSupplyStatus {
        try await service.getYieldSupplyStatus(tokenContractAddress: wrappedNative)
    }

    func liquidityProvider() -> YieldModuleLendingLiquidityProvider? {
        service.makeLendingLiquidityProvider()
    }

    func factoryAddress() throws -> String {
        try service.getYieldSupplyContractAddresses().factoryContractAddress
    }
}

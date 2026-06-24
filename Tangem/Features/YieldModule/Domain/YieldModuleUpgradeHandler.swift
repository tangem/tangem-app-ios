//
//  YieldModuleUpgradeHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation

// MARK: - Protocol

protocol YieldModuleUpgradeHandler {
    /// Checks the yield module version and, if an upgrade is needed and possible,
    /// wraps the given DEX transaction data inside an `upgradeToAndCall` invocation.
    /// Returns the original data unchanged when no upgrade is needed.
    func upgradeWrappedDataIfNeeded(_ data: ExpressTransactionData) async throws -> ExpressTransactionData

    /// Verifies that the module is already V2+ or can be upgraded before swap execution.
    func checkSwapAvailability() async throws

    /// Re-checks and stores the current on-chain implementation version after a successful upgrade.
    func refreshVersionAfterUpgrade() async throws

    /// Returns `true` when transaction data already contains `upgradeToAndCall`.
    func isUpgradeWrapped(_ data: ExpressTransactionData) -> Bool
}

// MARK: - Implementation

final class CommonYieldModuleUpgradeHandler: YieldModuleUpgradeHandler {
    private let versionChecker: YieldModuleVersionChecker
    private let yieldModuleAddress: String

    init(
        versionChecker: YieldModuleVersionChecker,
        yieldModuleAddress: String
    ) {
        self.versionChecker = versionChecker
        self.yieldModuleAddress = yieldModuleAddress
    }

    func upgradeWrappedDataIfNeeded(_ data: ExpressTransactionData) async throws -> ExpressTransactionData {
        guard !isUpgradeWrapped(data) else {
            return data
        }

        let status = try await versionChecker.checkVersion(userModuleAddress: yieldModuleAddress)

        switch status {
        case .upToDate:
            return data
        case .outdated(canUpgrade: false, _):
            throw ExpressProviderError.yieldModuleSwapUnavailable(.moduleUpgradeUnavailable)
        case .outdated(canUpgrade: true, let latestImplementation):
            guard let latestImplementation else { return data }
            return wrapWithUpgrade(data: data, latestImplementation: latestImplementation)
        }
    }

    func checkSwapAvailability() async throws {
        let status = try await versionChecker.checkVersion(userModuleAddress: yieldModuleAddress)

        if case .outdated(canUpgrade: false, _) = status {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.moduleUpgradeUnavailable)
        }
    }

    func refreshVersionAfterUpgrade() async throws {
        try await versionChecker.refreshStoredVersion(userModuleAddress: yieldModuleAddress)
    }

    func isUpgradeWrapped(_ data: ExpressTransactionData) -> Bool {
        data.txData?.removeHexPrefix().hasPrefix(Constants.upgradeToAndCallMethodId.removeHexPrefix()) == true
    }
}

// MARK: - Private

private extension CommonYieldModuleUpgradeHandler {
    func wrapWithUpgrade(data: ExpressTransactionData, latestImplementation: String) -> ExpressTransactionData {
        guard let originalTxData = data.txData else {
            return data
        }

        let method = UpgradeToAndCallMethod(
            newImplementation: latestImplementation,
            callData: Data(hexString: originalTxData)
        )

        return ExpressTransactionData(
            requestId: data.requestId,
            fromAmount: data.fromAmount,
            toAmount: data.toAmount,
            expressTransactionId: data.expressTransactionId,
            transactionType: data.transactionType,
            sourceAddress: data.sourceAddress,
            destinationAddress: yieldModuleAddress,
            extraDestinationId: data.extraDestinationId,
            txValue: data.txValue,
            txData: method.encodedData,
            otherNativeFee: data.otherNativeFee,
            estimatedGasLimit: data.estimatedGasLimit,
            externalTxId: data.externalTxId,
            externalTxURL: data.externalTxURL,
            payInAddress: data.payInAddress
        )
    }

    enum Constants {
        static let upgradeToAndCallMethodId = "0x4f1ef286"
    }
}

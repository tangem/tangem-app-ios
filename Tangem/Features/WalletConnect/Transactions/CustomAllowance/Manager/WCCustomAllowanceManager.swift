//
//  WCCustomAllowanceManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk

protocol WCCustomAllowanceManager {
    func createCustomAllowanceInput(
        approvalInfo: ApprovalInfo,
        asset: BlockaidChainScanResult.Asset,
        currentTransaction: WCSendableTransaction?,
        transactionData: WCHandleTransactionData,
        simulationResult: BlockaidChainScanResult?,
        updateAction: @MainActor @escaping (BigUInt) async -> Void,
        backAction: @MainActor @escaping () -> Void
    ) -> WCCustomAllowanceInput?

    func updateApprovalTransaction(
        originalTransaction: WCSendableTransaction,
        newAmount: BigUInt
    ) -> WCSendableTransaction?
}

final class CommonWCCustomAllowanceManager: WCCustomAllowanceManager {
    private let customAllowanceInputFactory: WCCustomAllowanceInputFactory

    init(customAllowanceInputFactory: WCCustomAllowanceInputFactory = CommonWCCustomAllowanceInputFactory()) {
        self.customAllowanceInputFactory = customAllowanceInputFactory
    }

    func createCustomAllowanceInput(
        approvalInfo: ApprovalInfo,
        asset: BlockaidChainScanResult.Asset,
        currentTransaction: WCSendableTransaction?,
        transactionData: WCHandleTransactionData,
        simulationResult: BlockaidChainScanResult?,
        updateAction: @MainActor @escaping (BigUInt) async -> Void,
        backAction: @MainActor @escaping () -> Void
    ) -> WCCustomAllowanceInput? {
        return customAllowanceInputFactory.createCustomAllowanceInput(
            approvalInfo: approvalInfo,
            asset: asset,
            currentTransaction: currentTransaction,
            transactionData: transactionData,
            simulationResult: simulationResult,
            updateAction: updateAction,
            backAction: backAction
        )
    }

    func updateApprovalTransaction(
        originalTransaction: WCSendableTransaction,
        newAmount: BigUInt
    ) -> WCSendableTransaction? {
        return WCApprovalAnalyzer.createUpdatedApproval(
            originalTransaction: originalTransaction,
            newAmount: newAmount
        )
    }
}

//
//  WCCustomAllowanceInputFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk

protocol WCCustomAllowanceInputFactory {
    func createCustomAllowanceInput(
        approvalInfo: ApprovalInfo,
        asset: BlockaidChainScanResult.Asset,
        currentTransaction: WCSendableTransaction?,
        transactionData: WCHandleTransactionData,
        simulationResult: BlockaidChainScanResult?,
        updateAction: @MainActor @escaping (BigUInt) async -> Void,
        backAction: @MainActor @escaping () -> Void
    ) -> WCCustomAllowanceInput?
}

final class CommonWCCustomAllowanceInputFactory: WCCustomAllowanceInputFactory {
    func createCustomAllowanceInput(
        approvalInfo: ApprovalInfo,
        asset: BlockaidChainScanResult.Asset,
        currentTransaction: WCSendableTransaction?,
        transactionData: WCHandleTransactionData,
        simulationResult: BlockaidChainScanResult?,
        updateAction: @MainActor @escaping (BigUInt) async -> Void,
        backAction: @MainActor @escaping () -> Void
    ) -> WCCustomAllowanceInput? {
        guard let tokenInfo = determineTokenInfoForApproval(
            approvalInfo: approvalInfo,
            currentTransaction: currentTransaction,
            transactionData: transactionData,
            simulationResult: simulationResult
        ) else {
            return nil
        }

        return WCCustomAllowanceInput(
            approvalInfo: approvalInfo,
            tokenInfo: tokenInfo,
            asset: asset,
            updateAction: updateAction,
            backAction: backAction
        )
    }

    private func determineTokenInfoForApproval(
        approvalInfo: ApprovalInfo,
        currentTransaction: WCSendableTransaction?,
        transactionData: WCHandleTransactionData,
        simulationResult: BlockaidChainScanResult?
    ) -> WCApprovalHelpers.TokenInfo? {
        guard let transaction = currentTransaction else {
            return WCApprovalHelpers.TokenInfo(
                symbol: "",
                decimals: 18,
                source: .wallet
            )
        }

        let walletModels: [any WalletModel]

        do {
            walletModels = try WCWalletModelsResolver.resolveWalletModels(
                account: transactionData.account, userWalletModel: transactionData.userWalletModel
            )
        } catch {
            WCLogger.error(self, error: error)
            return nil
        }

        return WCApprovalHelpers.determineTokenInfo(
            contractAddress: transaction.to,
            amount: approvalInfo.amount,
            walletModels: walletModels,
            simulationResult: simulationResult
        )
    }
}

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
        currentTransaction: WalletConnectEthTransaction?,
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
        currentTransaction: WalletConnectEthTransaction?,
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
        currentTransaction: WalletConnectEthTransaction?,
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

        return WCApprovalHelpers.determineTokenInfo(
            contractAddress: transaction.to,
            amount: approvalInfo.amount,
            userWalletModel: transactionData.userWalletModel,
            simulationResult: simulationResult
        )
    }
}

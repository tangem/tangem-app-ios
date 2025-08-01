//
//  WCTransactionSimulationDisplayService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemLocalization

struct WCTransactionSimulationDisplayService {
    func createDisplayModel(
        from simulationState: TransactionSimulationState,
        originalTransaction: WalletConnectEthTransaction?,
        userWalletModel: UserWalletModel,
        onApprovalEdit: ((ApprovalInfo, BlockaidChainScanResult.Asset) -> Void)?
    ) -> WCTransactionSimulationDisplayModel? {
        switch simulationState {
        case .notStarted, .loading:
            WCTransactionSimulationDisplayModel(
                cardTitle: Localization.wcEstimatedWalletChanges,
                content: .loading
            )

        case .simulationNotSupported(let method):
            WCTransactionSimulationDisplayModel(
                cardTitle: Localization.wcEstimatedWalletChanges,
                content: .failed(message: Localization.wcEstimationIsNotSupported(method))
            )

        case .simulationFailed(let error):
            WCTransactionSimulationDisplayModel(
                cardTitle: Localization.wcEstimatedWalletChanges,
                content: .failed(message: error.localizedDescription)
            )

        case .simulationSucceeded(let result):
            createSuccessDisplayModel(
                from: result,
                originalTransaction: originalTransaction,
                userWalletModel: userWalletModel,
                onApprovalEdit: onApprovalEdit
            )
        }
    }

    private func createSuccessDisplayModel(
        from result: BlockaidChainScanResult,
        originalTransaction: WalletConnectEthTransaction?,
        userWalletModel: UserWalletModel,
        onApprovalEdit: ((ApprovalInfo, BlockaidChainScanResult.Asset) -> Void)?
    ) -> WCTransactionSimulationDisplayModel {
        let cardTitle = result.approvals?.isEmpty == false ? Localization.wcAllowToSpend : Localization.wcEstimatedWalletChanges

        let sections = createSections(
            from: result,
            originalTransaction: originalTransaction,
            userWalletModel: userWalletModel,
            onApprovalEdit: onApprovalEdit
        )

        let successContent = WCTransactionSimulationDisplayModel.SuccessContent(
            sections: sections
        )

        return WCTransactionSimulationDisplayModel(
            cardTitle: cardTitle,
            content: .success(successContent)
        )
    }

    private func createSections(
        from result: BlockaidChainScanResult,
        originalTransaction: WalletConnectEthTransaction?,
        userWalletModel: UserWalletModel,
        onApprovalEdit: ((ApprovalInfo, BlockaidChainScanResult.Asset) -> Void)?
    ) -> [WCTransactionSimulationDisplayModel.Section] {
        if let diff = result.assetsDiff, diff.in.isNotEmpty || diff.out.isNotEmpty {
            return [.assetChanges(createAssetChangesSection(from: diff))]
        }

        if let approvals = result.approvals, approvals.isNotEmpty {
            return [.approvals(createApprovalsSection(
                from: approvals,
                originalTransaction: originalTransaction,
                userWalletModel: userWalletModel,
                onApprovalEdit: onApprovalEdit,
                simulationResult: result
            ))]
        }

        return [.noChanges]
    }

    private func createAssetChangesSection(
        from diff: BlockaidChainScanResult.AssetDiff
    ) -> WCTransactionSimulationDisplayModel.AssetChangesSection {
        let sendItems = diff.out.map { asset in
            WCTransactionSimulationDisplayModel.AssetItem(
                direction: .send,
                iconURL: asset.logoURL,
                formattedAmount: formatAssetAmount(asset),
                symbol: asset.symbol ?? asset.name ?? asset.assetType,
                asset: asset
            )
        }

        let receiveItems = diff.in.map { asset in
            WCTransactionSimulationDisplayModel.AssetItem(
                direction: .receive,
                iconURL: asset.logoURL,
                formattedAmount: formatAssetAmount(asset),
                symbol: asset.symbol ?? asset.name ?? asset.assetType,
                asset: asset
            )
        }

        return WCTransactionSimulationDisplayModel.AssetChangesSection(
            sendItems: sendItems,
            receiveItems: receiveItems
        )
    }

    private func createApprovalsSection(
        from approvals: [BlockaidChainScanResult.Asset],
        originalTransaction: WalletConnectEthTransaction?,
        userWalletModel: UserWalletModel,
        onApprovalEdit: ((ApprovalInfo, BlockaidChainScanResult.Asset) -> Void)?,
        simulationResult: BlockaidChainScanResult
    ) -> WCTransactionSimulationDisplayModel.ApprovalsSection {
        let items = approvals.map { asset in
            createApprovalItem(
                from: asset,
                originalTransaction: originalTransaction,
                userWalletModel: userWalletModel,
                onApprovalEdit: onApprovalEdit,
                simulationResult: simulationResult
            )
        }

        return WCTransactionSimulationDisplayModel.ApprovalsSection(items: items)
    }

    private func createApprovalItem(
        from asset: BlockaidChainScanResult.Asset,
        originalTransaction: WalletConnectEthTransaction?,
        userWalletModel: UserWalletModel,
        onApprovalEdit: ((ApprovalInfo, BlockaidChainScanResult.Asset) -> Void)?,
        simulationResult: BlockaidChainScanResult?
    ) -> WCTransactionSimulationDisplayModel.ApprovalItem {
        var approvalInfo: ApprovalInfo?
        var isEditable = false

        if let originalTransaction = originalTransaction {
            approvalInfo = WCApprovalAnalyzer.analyzeApproval(transaction: originalTransaction)
            isEditable = approvalInfo?.isEditable == true
        }

        let leftContent: WCTransactionSimulationDisplayModel.ApprovalItem.LeftContent
        if isEditable, let approvalInfo = approvalInfo {
            let formattedAmount = formatApprovalAmount(
                approvalInfo,
                asset: asset,
                userWalletModel: userWalletModel,
                simulationResult: simulationResult,
                originalTransaction: originalTransaction
            )
            leftContent = .editable(iconURL: asset.logoURL, formattedAmount: formattedAmount, asset: asset)
        } else {
            leftContent = .nonEditable
        }

        let rightContent: WCTransactionSimulationDisplayModel.ApprovalItem.RightContent
        if isEditable {
            rightContent = .empty
        } else {
            rightContent = .tokenInfo(
                formattedAmount: "Unlimited \(asset.name ?? asset.symbol ?? asset.assetType)",
                iconURL: asset.logoURL,
                asset: asset
            )
        }

        let onEdit: (() -> Void)? = isEditable && approvalInfo != nil && onApprovalEdit != nil
            ? { onApprovalEdit!(approvalInfo!, asset) }
            : nil

        return WCTransactionSimulationDisplayModel.ApprovalItem(
            isEditable: isEditable,
            leftContent: leftContent,
            rightContent: rightContent,
            onEdit: onEdit,
            asset: asset
        )
    }

    private func formatApprovalAmount(
        _ approvalInfo: ApprovalInfo,
        asset: BlockaidChainScanResult.Asset,
        userWalletModel: UserWalletModel,
        simulationResult: BlockaidChainScanResult?,
        originalTransaction: WalletConnectEthTransaction?
    ) -> String {
        if approvalInfo.isUnlimited {
            return "Unlimited \(asset.symbol ?? asset.name ?? "")"
        } else {
            let contractAddress = originalTransaction?.to ?? ""

            guard
                let tokenInfo = WCApprovalHelpers.determineTokenInfo(
                    contractAddress: contractAddress,
                    amount: approvalInfo.amount,
                    userWalletModel: userWalletModel,
                    simulationResult: simulationResult
                )
            else {
                return "Invalid token"
            }

            let converter = WCCustomAllowanceAmountConverter(tokenInfo: tokenInfo)
            let formatted = converter.formatBigUIntForDisplay(approvalInfo.amount)
            return formatted
        }
    }

    private func formatAssetAmount(_ asset: BlockaidChainScanResult.Asset) -> String {
        guard let amount = asset.amount, amount != 0 else {
            return asset.name ?? ""
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8

        return formatter.string(from: amount as NSNumber) ?? "\(amount)"
    }
}

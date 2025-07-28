//
//  WCTransactionSimulationDisplayService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

// [REDACTED_TODO_COMMENT]
/// Service for creating display model from transaction simulation data
struct WCTransactionSimulationDisplayService {
    // MARK: - Public Methods

    func createDisplayModel(
        from simulationState: TransactionSimulationState,
        originalTransaction: WalletConnectEthTransaction?,
        userWalletModel: UserWalletModel,
        onApprovalEdit: ((ApprovalInfo, BlockaidChainScanResult.Asset) -> Void)?
    ) -> WCTransactionSimulationDisplayModel {
        switch simulationState {
        case .notStarted, .loading:
            return WCTransactionSimulationDisplayModel(
                cardTitle: "Estimated wallet changes",
                content: .loading
            )

        case .simulationNotSupported(let method):
            return WCTransactionSimulationDisplayModel(
                cardTitle: "Estimated wallet changes",
                content: .failed(message: "Estimation is not supported for \(method)")
            )

        case .simulationFailed(let error):
            return WCTransactionSimulationDisplayModel(
                cardTitle: "Estimated wallet changes",
                content: .failed(message: error.localizedDescription)
            )

        case .simulationSucceeded(let result):
            return createSuccessDisplayModel(
                from: result,
                originalTransaction: originalTransaction,
                userWalletModel: userWalletModel,
                onApprovalEdit: onApprovalEdit
            )
        }
    }

    // MARK: - Private Methods

    private func createSuccessDisplayModel(
        from result: BlockaidChainScanResult,
        originalTransaction: WalletConnectEthTransaction?,
        userWalletModel: UserWalletModel,
        onApprovalEdit: ((ApprovalInfo, BlockaidChainScanResult.Asset) -> Void)?
    ) -> WCTransactionSimulationDisplayModel {
        // Determine card title
        let cardTitle = result.approvals?.isEmpty == false ? "Allow to spend" : "Estimated wallet changes"

        // Create banner if needed
        let validationBanner = createValidationBanner(from: result.validationStatus)

        // Create content sections
        let sections = createSections(
            from: result,
            originalTransaction: originalTransaction,
            userWalletModel: userWalletModel,
            onApprovalEdit: onApprovalEdit
        )

        let successContent = WCTransactionSimulationDisplayModel.SuccessContent(
            validationBanner: validationBanner,
            sections: sections
        )

        return WCTransactionSimulationDisplayModel(
            cardTitle: cardTitle,
            content: .success(successContent)
        )
    }

    private func createValidationBanner(
        from status: BlockaidChainScanResult.ValidationStatus?
    ) -> WCTransactionSimulationDisplayModel.ValidationBanner? {
        guard let status = status, status != .benign else { return nil }

        switch status {
        case .malicious:
            return WCTransactionSimulationDisplayModel.ValidationBanner(
                type: .malicious,
                title: "Malicious transaction",
                description: status.description
            )
        case .warning:
            return WCTransactionSimulationDisplayModel.ValidationBanner(
                type: .suspicious,
                title: "Suspicious transaction",
                description: status.description
            )
        case .benign:
            return nil
        }
    }

    private func createSections(
        from result: BlockaidChainScanResult,
        originalTransaction: WalletConnectEthTransaction?,
        userWalletModel: UserWalletModel,
        onApprovalEdit: ((ApprovalInfo, BlockaidChainScanResult.Asset) -> Void)?
    ) -> [WCTransactionSimulationDisplayModel.Section] {
        // 1. Check asset changes
        if let diff = result.assetsDiff, diff.in.isNotEmpty || diff.out.isNotEmpty {
            return [.assetChanges(createAssetChangesSection(from: diff))]
        }

        // 2. Check approvals
        if let approvals = result.approvals, approvals.isNotEmpty {
            return [.approvals(createApprovalsSection(
                from: approvals,
                originalTransaction: originalTransaction,
                userWalletModel: userWalletModel,
                onApprovalEdit: onApprovalEdit,
                simulationResult: result
            ))]
        }

        // 3. No changes
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
        // Analyze transaction to determine editable approval
        var approvalInfo: ApprovalInfo?
        var isEditable = false

        if let originalTransaction = originalTransaction {
            approvalInfo = WCApprovalAnalyzer.analyzeApproval(transaction: originalTransaction)
            isEditable = approvalInfo?.isEditable == true
        }

        // Determine left content
        let leftContent: WCTransactionSimulationDisplayModel.ApprovalItem.LeftContent
        if isEditable, let approvalInfo = approvalInfo {
            // Editable approval - show token icon and current amount
            let formattedAmount = formatApprovalAmount(
                approvalInfo,
                asset: asset,
                userWalletModel: userWalletModel,
                simulationResult: simulationResult,
                originalTransaction: originalTransaction
            )
            leftContent = .editable(iconURL: asset.logoURL, formattedAmount: formattedAmount, asset: asset)
        } else {
            // Non-editable approval - show standard "Approve" icon
            leftContent = .nonEditable
        }

        // Determine right content
        let rightContent: WCTransactionSimulationDisplayModel.ApprovalItem.RightContent
        if isEditable {
            // For editable approval, only "Edit" button on the right, no text
            rightContent = .empty
        } else {
            // For non-editable approval, show token information
            rightContent = .tokenInfo(
                formattedAmount: "Unlimited \(asset.name ?? asset.symbol ?? asset.assetType)",
                iconURL: asset.logoURL,
                asset: asset
            )
        }

        // Create onEdit callback if approval is editable
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
            // Get the correct contract address from transaction
            let contractAddress = originalTransaction?.to ?? ""

            // Determine correct decimals through WCApprovalHelpers

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

            // Use WCCustomAllowanceAmountConverter for proper formatting
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

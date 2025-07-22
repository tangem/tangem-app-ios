//
//  WCTransactionSimulationDisplayModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// Data model for displaying transaction simulation results
struct WCTransactionSimulationDisplayModel {
    let cardTitle: String
    let content: Content

    enum Content {
        case loading
        case failed(message: String)
        case success(SuccessContent)
    }

    struct SuccessContent {
        let validationBanner: ValidationBanner?
        let sections: [Section]
    }

    struct ValidationBanner {
        let type: BannerType
        let title: String
        let description: String

        enum BannerType {
            case malicious
            case suspicious
        }
    }

    enum Section {
        case assetChanges(AssetChangesSection)
        case approvals(ApprovalsSection)
        case noChanges
    }

    struct AssetChangesSection {
        let sendItems: [AssetItem]
        let receiveItems: [AssetItem]
    }

    struct ApprovalsSection {
        let items: [ApprovalItem]
    }

    struct AssetItem: Equatable {
        let direction: Direction
        let iconURL: URL?
        let formattedAmount: String
        let symbol: String
        let asset: BlockaidChainScanResult.Asset // Original asset for type determination

        enum Direction {
            case send
            case receive
        }
    }

    struct ApprovalItem {
        let isEditable: Bool
        let leftContent: LeftContent
        let rightContent: RightContent
        let onEdit: (() -> Void)?
        let asset: BlockaidChainScanResult.Asset // Original asset for type determination

        enum LeftContent {
            case editable(iconURL: URL?, formattedAmount: String, asset: BlockaidChainScanResult.Asset)
            case nonEditable
        }

        enum RightContent {
            case tokenInfo(formattedAmount: String, iconURL: URL?, asset: BlockaidChainScanResult.Asset)
            case empty
        }
    }
}

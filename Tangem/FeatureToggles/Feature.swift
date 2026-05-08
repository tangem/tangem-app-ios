//
//  Feature.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum Feature: String, Hashable, CaseIterable {
    case disableFirmwareVersionLimit
    case visa // [REDACTED_TODO_COMMENT]
    case redesign
    case exchangeOnlyWithinSingleAddress
    case experimentService
    case walletConnectBitcoin
    case mainQRScan
    case surveySparrow
    case mobileWalletTokenAutoSync
    case gaslessDexAndApprove
    case solanaTxHistoryEnabled
    case solanaScaledUIEnabled
    case dynamicAddresses
    case usdtRevokeGaslessFee
    case newPromotionBanners
    case swapPipelineV2
    case xrplTransactionHistory
    case sendBalanceSendSplitRows
    case swapStoriesV2
    case swapInProgressV2
    case swapPendingTxStateDate
    case dexApproveNotificationV2
    case manageTokensImprovements
    case swapSimpleMode

    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .visa: return "Visa"
        case .redesign: return "Redesign"
        case .exchangeOnlyWithinSingleAddress: return "Filter by `exchangeOnlyWithinSingleAddress`"
        case .experimentService: return "Experiment service"
        case .walletConnectBitcoin: return "WalletConnect Bitcoin"
        case .mainQRScan: return "Main QR Scan"
        case .surveySparrow: return "SurveySparrow service integration"
        case .mobileWalletTokenAutoSync: return "Wallet Token Auto Sync"
        case .gaslessDexAndApprove: return "Gasless Fees For Dex and Approve"
        case .solanaTxHistoryEnabled: return "Solana Transaction History"
        case .solanaScaledUIEnabled: return "Solana Scaled UI"
        case .dynamicAddresses: return "XPUB Dynamic-addresses support"
        case .usdtRevokeGaslessFee: return "USDT Revoke Gasless Fee"
        case .newPromotionBanners: return "New Promotion Banners"
        case .sendBalanceSendSplitRows: return "Send Balance/Send split rows"
        case .swapPipelineV2: return "Swap Pipeline V2"
        case .xrplTransactionHistory: return "XRPL Transaction History"
        case .swapStoriesV2: return "Swap Stories V2"
        case .swapInProgressV2: return "Swap In Progress V2"
        case .swapPendingTxStateDate: return "Swap Pending Tx State Date"
        case .dexApproveNotificationV2: return "DEX Approve Notification V2"
        case .manageTokensImprovements: return "Manage Tokens Improvements"
        case .swapSimpleMode: return "Swap Simple Mode"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .visa: return .unspecified
        case .redesign: return .unspecified
        case .exchangeOnlyWithinSingleAddress: return .unspecified
        case .experimentService: return .unspecified
        case .walletConnectBitcoin: return .unspecified
        case .mainQRScan: return .version("5.36")
        case .surveySparrow: return .unspecified
        case .mobileWalletTokenAutoSync: return .version("5.38")
        case .gaslessDexAndApprove: return .version("5.37")
        case .solanaTxHistoryEnabled: return .unspecified
        case .solanaScaledUIEnabled: return .unspecified
        case .dynamicAddresses: return .unspecified
        case .usdtRevokeGaslessFee: return .unspecified
        case .newPromotionBanners: return .version("5.37")
        case .swapPipelineV2: return .version("5.38")
        case .swapStoriesV2: return .version("5.38")
        case .xrplTransactionHistory: return .unspecified
        case .sendBalanceSendSplitRows: return .unspecified
        case .swapInProgressV2: return .unspecified
        case .swapPendingTxStateDate: return .unspecified
        case .dexApproveNotificationV2: return .unspecified
        case .manageTokensImprovements: return .unspecified
        case .swapSimpleMode: return .unspecified
        }
    }
}

extension Feature {
    enum ReleaseVersion: Hashable {
        /// This case is for an undetermined release date
        case unspecified

        /// Version in the format "1.1.0" or "1.2"
        case version(_ version: String)

        var version: String? {
            switch self {
            case .unspecified: return nil
            case .version(let version): return version
            }
        }
    }
}

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
    case gaslessDexAndApprove
    case solanaTxHistoryEnabled
    case solanaScaledUIEnabled
    case dynamicAddresses
    case usdtRevokeGaslessFee
    case yieldModuleUpdate
    case swapPipelineV2
    case tangemPayMobileOnboarding
    case onrampNativePayment
    case xrplTransactionHistory
    case sendBalanceSendSplitRows
    case swapStoriesV2
    case addFundsStage1
    case swapProviderTypeFilter
    case swapPendingTxStateDate
    case swapInProgressV2
    case dexApproveNotificationV2
    case manageTokensImprovements
    case swapSimpleMode
    case swapMaxAmountFractions
    case pushNotificationsSettings
    case swapExchangeRateDisplay
    case swapRateExperience
    case yieldApyBoostPromo
    case deeplinkPresentationWay
    case transactionHistoryV2
    case adiMainScreenDefault
    case tangemPayMultipleCards
    case transfers
    case tangemPaySpendRedesign

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
        case .gaslessDexAndApprove: return "Gasless Fees For Dex and Approve"
        case .solanaTxHistoryEnabled: return "Solana Transaction History"
        case .solanaScaledUIEnabled: return "Solana Scaled UI"
        case .dynamicAddresses: return "XPUB Dynamic-addresses support"
        case .usdtRevokeGaslessFee: return "USDT Revoke Gasless Fee"
        case .yieldModuleUpdate: return "1326_Yield_mode_DEX_support"
        case .sendBalanceSendSplitRows: return "Send Balance/Send split rows"
        case .swapPipelineV2: return "Swap Pipeline V2"
        case .tangemPayMobileOnboarding: return "1489_TangemPayNewMobileOnboarding"
        case .onrampNativePayment: return "Onramp Native Payment (Apple Pay)"
        case .xrplTransactionHistory: return "XRPL Transaction History"
        case .swapStoriesV2: return "Swap Stories V2"
        case .swapProviderTypeFilter: return "13675_Swap_Provider_Type_Filter"
        case .swapInProgressV2: return "Swap In Progress V2"
        case .swapPendingTxStateDate: return "Swap Pending Tx State Date"
        case .dexApproveNotificationV2: return "DEX Approve Notification V2"
        case .manageTokensImprovements: return "Manage Tokens Improvements"
        case .swapSimpleMode: return "13763_Swap_Simple_Mode"
        case .swapMaxAmountFractions: return "13789_Swap_Max_Amount_Fractions"
        case .adiMainScreenDefault: return "14071_show_ADI_on_main_screen"
        case .pushNotificationsSettings: return "13906_Push_Notifications_Settings"
        case .swapExchangeRateDisplay: return "13768_Swap_Exchange_Rate_Display"
        case .swapRateExperience: return "13956_Swap_Rate_Experience"
        case .yieldApyBoostPromo: return "13839_Referral_programm._Yield_promotion_V2"
        case .deeplinkPresentationWay: return "13880_Deeplink_Presentation_Way"
        case .addFundsStage1: return "[REDACTED_INFO]_ADDFUNDS_STAGE_1"
        case .transactionHistoryV2: return "139_Transaction_History_V2"
        case .tangemPayMultipleCards: return "1156_TangemPay_Multiple_Cards"
        case .transfers: return "14042_Transfers"
        case .tangemPaySpendRedesign: return "1540_TangemPay_Redesign"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .visa: return .unspecified
        case .redesign: return .version("5.40")
        case .exchangeOnlyWithinSingleAddress: return .unspecified
        case .experimentService: return .unspecified
        case .walletConnectBitcoin: return .unspecified
        case .mainQRScan: return .version("5.36")
        case .surveySparrow: return .unspecified
        case .gaslessDexAndApprove: return .version("5.37")
        case .solanaTxHistoryEnabled: return .version("5.39")
        case .solanaScaledUIEnabled: return .version("5.39")
        case .dynamicAddresses: return .version("5.39")
        case .usdtRevokeGaslessFee: return .unspecified
        case .yieldModuleUpdate: return .unspecified
        case .swapPipelineV2: return .version("5.38")
        case .tangemPayMobileOnboarding: return .version("5.39")
        case .onrampNativePayment: return .version("5.39")
        case .xrplTransactionHistory: return .unspecified
        case .sendBalanceSendSplitRows: return .version("5.39")
        case .swapStoriesV2: return .version("5.38")
        case .swapProviderTypeFilter: return .version("5.39")
        case .swapInProgressV2: return .version("5.39")
        case .swapPendingTxStateDate: return .version("5.39")
        case .dexApproveNotificationV2: return .version("5.39")
        case .manageTokensImprovements: return .version("5.39")
        case .swapSimpleMode: return .version("5.39")
        case .swapMaxAmountFractions: return .version("5.39")
        case .pushNotificationsSettings: return .unspecified
        case .adiMainScreenDefault: return .unspecified
        case .swapExchangeRateDisplay: return .version("5.39")
        case .swapRateExperience: return .version("5.39")
        case .yieldApyBoostPromo: return .unspecified
        case .deeplinkPresentationWay: return .unspecified
        case .transactionHistoryV2: return .unspecified
        case .addFundsStage1: return .version("5.39")
        case .tangemPayMultipleCards: return .unspecified
        case .transfers: return .version("5.40")
        case .tangemPaySpendRedesign: return .unspecified
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

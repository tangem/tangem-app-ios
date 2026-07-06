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
    case walletConnectBitcoin
    case surveySparrow
    case usdtRevokeGaslessFee
    case yieldModuleUpdate
    case xrplTransactionHistory
    case pushNotificationsSettings
    case deeplinkPresentationWay
    case transactionHistoryV2
    case tangemPayMultipleCards
    case transfers
    case memoValidationBeforeConfirm
    case tangemPaySpendRedesign
    case supportChat
    case supportChatSwap
    case onrampApplePayHistoryFallback
    case mobileWalletMultiCreation
    case approveFlowV2
    case addAndOrganizeRedesign
    case addressBook
    case swapChooseBestDEX
    case hideStoriesInMobileWallet
    case bitcoinDexSwap
    case solanaUnstakeValidation

    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .visa: return "Visa"
        case .redesign: return "Redesign"
        case .exchangeOnlyWithinSingleAddress: return "Filter by `exchangeOnlyWithinSingleAddress`"
        case .walletConnectBitcoin: return "WalletConnect Bitcoin"
        case .surveySparrow: return "SurveySparrow service integration"
        case .usdtRevokeGaslessFee: return "USDT Revoke Gasless Fee"
        case .yieldModuleUpdate: return "1326_Yield_mode_DEX_support"
        case .xrplTransactionHistory: return "XRPL Transaction History"
        case .pushNotificationsSettings: return "13906_Push_Notifications_Settings"
        case .deeplinkPresentationWay: return "13880_Deeplink_Presentation_Way"
        case .transactionHistoryV2: return "139_Transaction_History_V2"
        case .tangemPayMultipleCards: return "1156_TangemPay_Multiple_Cards"
        case .transfers: return "14042_Transfers"
        case .memoValidationBeforeConfirm: return "14202_Memo_Validation_Before_Confirm"
        case .tangemPaySpendRedesign: return "1540_TangemPay_Redesign"
        case .supportChat: return "13815_Support_Chat_(Usedesk)"
        case .supportChatSwap: return "13815_Support_Chat_in_Swap_(Usedesk)"
        case .onrampApplePayHistoryFallback: return "14115_Onramp_Apple_Pay_History_Fallback"
        case .mobileWalletMultiCreation: return "14278_Mobile_wallet_multi_creation"
        case .approveFlowV2: return "13786_Update_Swap_Phase_2_Permissions"
        case .addAndOrganizeRedesign: return "13923_Support_Add_&_Organize_feature_in_redesign"
        case .swapChooseBestDEX: return "14412_[SWAP_Ph.3]_Chose_Best_DEX_instead_of_best_rate"
        case .addressBook: return "10801-Address-Book"
        case .bitcoinDexSwap: return "14413_Bitcoin_support_for_DEX_(LiFi_/_SwapKit)"
        case .hideStoriesInMobileWallet: return "1512_Hide_Stories_In_Mobile_Wallet"
        case .solanaUnstakeValidation: return "[REDACTED_INFO]_solana_unstake_validation"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .visa: return .unspecified
        case .redesign: return .version("6.0")
        case .exchangeOnlyWithinSingleAddress: return .unspecified
        case .walletConnectBitcoin: return .unspecified
        case .surveySparrow: return .unspecified
        case .usdtRevokeGaslessFee: return .unspecified
        case .yieldModuleUpdate: return .unspecified
        case .xrplTransactionHistory: return .unspecified
        case .pushNotificationsSettings: return .unspecified
        case .deeplinkPresentationWay: return .unspecified
        case .transactionHistoryV2: return .unspecified
        case .tangemPayMultipleCards: return .version("6.0")
        case .transfers: return .version("6.0")
        case .memoValidationBeforeConfirm: return .version("6.0")
        case .tangemPaySpendRedesign: return .version("6.0")
        case .supportChat: return .unspecified
        case .supportChatSwap: return .unspecified
        case .onrampApplePayHistoryFallback: return .version("6.0")
        case .mobileWalletMultiCreation: return .unspecified
        case .approveFlowV2: return .version("6.0")
        case .addAndOrganizeRedesign: return .version("6.0")
        case .swapChooseBestDEX: return .version("6.0")
        case .addressBook: return .unspecified
        case .bitcoinDexSwap: return .version("6.0")
        case .hideStoriesInMobileWallet: return .version("6.0")
        case .solanaUnstakeValidation: return .version("6.0")
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

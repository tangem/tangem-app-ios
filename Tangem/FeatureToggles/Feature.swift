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
    case exchangeOnlyWithinSingleAddress
    case walletConnectBitcoin
    case surveySparrow
    case gaslessYieldFee
    case usdtRevokeGaslessFee
    case yieldModuleUpdate
    case xrplTransactionHistory
    case pushNotificationsSettings
    case deeplinkPresentationWay
    case transactionHistoryV2
    case forceUpdate
    case tangemPayTiers
    case supportChat
    case supportChatSwap
    case mobileWalletMultiCreation
    case stakingTransactionValidation
    case sendWithSwapAvailabilityCheck
    case swapFiatCalculation
    case addressBook
    case hideStoriesInMobileWallet
    case marketingBanners
    case stakingRegionUnavailable
    case forYou
    case tangemPayVirtualAccount
    case highFeeWarning
    case priceAlertsSubscription
    case promoCampaignsAttribution
    case onboardingPushNotificationDoubleAsk
    case mainPushNotificationDoubleAsk
    case backendAuthentication
    case bitcoinLikePsbtSwap

    /// Feature toggle `name` format: `TWI-XXX_description_snake_case` or `IOS-XXX_description_snake_case`.
    /// Use the `IOS-` prefix when the toggle has no TWI ticket or tracks a decomposed sub-task of one.
    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .visa: return "Visa"
        case .exchangeOnlyWithinSingleAddress: return "Filter by `exchangeOnlyWithinSingleAddress`"
        case .walletConnectBitcoin: return "WalletConnect Bitcoin"
        case .surveySparrow: return "SurveySparrow service integration"
        case .gaslessYieldFee: return "TWI-1327_smart_gas_support_for_tokens_in_yield_mode"
        case .usdtRevokeGaslessFee: return "USDT Revoke Gasless Fee"
        case .yieldModuleUpdate: return "1326_Yield_mode_DEX_support"
        case .xrplTransactionHistory: return "XRPL Transaction History"
        case .pushNotificationsSettings: return "13906_Push_Notifications_Settings"
        case .deeplinkPresentationWay: return "13880_Deeplink_Presentation_Way"
        case .transactionHistoryV2: return "139_Transaction_History_V2"
        case .forceUpdate: return "[REDACTED_INFO]_force_update"
        case .tangemPayTiers: return "TWI-1066_tangem_pay_tiers_1"
        case .supportChat: return "13815_Support_Chat_(Usedesk)"
        case .supportChatSwap: return "13815_Support_Chat_in_Swap_(Usedesk)"
        case .mobileWalletMultiCreation: return "14278_Mobile_wallet_multi_creation"
        case .stakingTransactionValidation: return "TWI-1602_move_away_from_blind_signing_in_staking"
        case .sendWithSwapAvailabilityCheck: return "14316_Send_With_Swap_Availability_Check"
        case .swapFiatCalculation: return "14315_Swap_Fiat_Calculation"
        case .addressBook: return "TWI-83_address_book"
        case .hideStoriesInMobileWallet: return "1512_Hide_Stories_In_Mobile_Wallet"
        case .marketingBanners: return "TWI-1522_special_offer_promo_placement_for_onramp_and_swaps"
        case .stakingRegionUnavailable: return "[REDACTED_INFO]_p2p_staking_region_unavailable"
        case .forYou: return "TWI-1469_for_you_product_shelves_add_indicators"
        case .highFeeWarning: return "TWI-1367_high_fee_warning"
        case .priceAlertsSubscription: return "TWI-1603_price_alerts_subscription"
        case .tangemPayVirtualAccount: return "TWI-1638_tangempay_virtual_account"
        case .onboardingPushNotificationDoubleAsk: return "TWI-1403_onboarding_push_notification_double_ask"
        case .mainPushNotificationDoubleAsk: return "TWI-1403_main_push_notification_double_ask"
        case .promoCampaignsAttribution: return "TWI-1637_promo_campaigns_attribution"
        case .backendAuthentication: return "[REDACTED_INFO]_backend_authentication"
        case .bitcoinLikePsbtSwap: return "TWI-1668_support_other_bitcoin_like_tokens_for_psbt_signature"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .visa: return .unspecified
        case .exchangeOnlyWithinSingleAddress: return .unspecified
        case .walletConnectBitcoin: return .unspecified
        case .surveySparrow: return .version("6.1")
        case .gaslessYieldFee: return .unspecified
        case .usdtRevokeGaslessFee: return .unspecified
        case .yieldModuleUpdate: return .version("6.1")
        case .xrplTransactionHistory: return .unspecified
        case .pushNotificationsSettings: return .unspecified
        case .deeplinkPresentationWay: return .unspecified
        case .transactionHistoryV2: return .unspecified
        case .forceUpdate: return .unspecified
        case .tangemPayTiers: return .version("6.1")
        case .supportChat: return .version("6.1")
        case .supportChatSwap: return .version("6.1")
        case .mobileWalletMultiCreation: return .unspecified
        case .stakingTransactionValidation: return .unspecified
        case .sendWithSwapAvailabilityCheck: return .version("6.1")
        case .swapFiatCalculation: return .version("6.1")
        case .addressBook: return .version("6.1")
        case .hideStoriesInMobileWallet: return .version("6.1")
        case .marketingBanners: return .unspecified
        case .stakingRegionUnavailable: return .version("6.1")
        case .forYou: return .unspecified
        case .highFeeWarning: return .version("6.1")
        case .priceAlertsSubscription: return .unspecified
        case .tangemPayVirtualAccount: return .version("6.1")
        case .onboardingPushNotificationDoubleAsk: return .version("6.1")
        case .mainPushNotificationDoubleAsk: return .version("6.1")
        case .promoCampaignsAttribution: return .unspecified
        case .backendAuthentication: return .unspecified
        case .bitcoinLikePsbtSwap: return .unspecified
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

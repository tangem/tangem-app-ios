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
    case gaslessYieldFee
    case usdtRevokeGaslessFee
    case tronGasless
    case xrplTransactionHistory
    case deeplinkPresentationWay
    case transactionHistoryV2
    case mobileWalletMultiCreation
    case stakingFlowV2
    case forYou
    case tangemPayMultichain
    case priceAlertsSubscription
    case backup4cards
    case backendAuthentication
    case tangemPayAddFundsWithdrawRework
    case swapHideZeroBalanceSource
    case onrampPaymentMethodThemedImages
    case chooseTokenPulseAnimation
    case hotWalletDexRatesUntilDeposit
    case polymarket
    case mobileWalletBackup
    case swapDeeplinkParameters
    case walletCardsBackupReport
    case jointAccounts
    case ethPolLocalStakingValidation
    case yieldDexTransferDetection
    case tangemPayCashback
    case swapChooseTokenWholeAreaTap
    case welcomeScreenV2
    case tangemPayPlastic
    case gachaMachine
    case openTelemetryMetrics
    case expressGeoRestrictions

    /// Feature toggle `name` format: `TWI-XXX_description_snake_case` or `IOS-XXX_description_snake_case`.
    /// Use the `IOS-` prefix when the toggle has no TWI ticket or tracks a decomposed sub-task of one.
    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .visa: return "Visa"
        case .exchangeOnlyWithinSingleAddress: return "Filter by `exchangeOnlyWithinSingleAddress`"
        case .walletConnectBitcoin: return "WalletConnect Bitcoin"
        case .gaslessYieldFee: return "TWI-1327_smart_gas_support_for_tokens_in_yield_mode"
        case .usdtRevokeGaslessFee: return "USDT Revoke Gasless Fee"
        case .tronGasless: return "TWI-1259_tron_gasless"
        case .xrplTransactionHistory: return "XRPL Transaction History"
        case .deeplinkPresentationWay: return "13880_Deeplink_Presentation_Way"
        case .transactionHistoryV2: return "139_Transaction_History_V2"
        case .mobileWalletMultiCreation: return "14278_Mobile_wallet_multi_creation"
        case .stakingFlowV2: return "[REDACTED_INFO]_staking_flow_v2"
        case .forYou: return "TWI-1469_for_you_product_shelves_add_indicators"
        case .priceAlertsSubscription: return "TWI-1603_price_alerts_subscription"
        case .backup4cards: return "[REDACTED_INFO]_backup_4_cards_fw8"
        case .tangemPayMultichain: return "TWI-1684_tangem_pay_multichain"
        case .backendAuthentication: return "[REDACTED_INFO]_backend_authentication"
        case .tangemPayAddFundsWithdrawRework: return "[REDACTED_INFO]_tangem_pay_add_funds_withdraw_rework"
        case .swapHideZeroBalanceSource: return "[REDACTED_INFO]_hide_zero_balance_tokens_in_swap_source"
        case .onrampPaymentMethodThemedImages: return "[REDACTED_INFO]_two_payment_method_pictures"
        case .chooseTokenPulseAnimation: return "[REDACTED_INFO]_choose_token_pulse_animation"
        case .hotWalletDexRatesUntilDeposit: return "[REDACTED_INFO]_hot_wallet_dex_rates_until_deposit"
        case .polymarket: return "TWI-1576_polymarket"
        case .mobileWalletBackup: return "[REDACTED_INFO]_mobile_wallet_backup"
        case .swapDeeplinkParameters: return "[REDACTED_INFO]_swap_deeplink_parameters"
        case .walletCardsBackupReport: return "[REDACTED_INFO]_cardlinked_status_update_stage2"
        case .jointAccounts: return "TWI-1611_joint_accounts"
        case .ethPolLocalStakingValidation: return "[REDACTED_INFO]_eth_pol_local_staking_validation"
        case .yieldDexTransferDetection: return "[REDACTED_INFO]_yield_dex_transfer_detection"
        case .tangemPayCashback: return "TWI-1192_tangem_pay_cashback"
        case .swapChooseTokenWholeAreaTap: return "[REDACTED_INFO]_choose_token_whole_area_tap"
        case .welcomeScreenV2: return "TWI-1747_welcome_screen_v2"
        case .tangemPayPlastic: return "TWI-1157_tangem_pay_plastic"
        case .gachaMachine: return "TWI-1640_gacha_machine"
        case .openTelemetryMetrics: return "TWI-1627_opentelemetry_metrics_mirroring"
        case .expressGeoRestrictions: return "[REDACTED_INFO]_express_geo_restrictions"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .visa: return .unspecified
        case .exchangeOnlyWithinSingleAddress: return .unspecified
        case .walletConnectBitcoin: return .unspecified
        case .gaslessYieldFee: return .unspecified
        case .usdtRevokeGaslessFee: return .unspecified
        case .tronGasless: return .unspecified
        case .xrplTransactionHistory: return .unspecified
        case .deeplinkPresentationWay: return .unspecified
        case .transactionHistoryV2: return .unspecified
        case .mobileWalletMultiCreation: return .unspecified
        case .stakingFlowV2: return .unspecified
        case .forYou: return .unspecified
        case .priceAlertsSubscription: return .unspecified
        case .tangemPayMultichain: return .version("6.3")
        case .backup4cards: return .unspecified
        case .backendAuthentication: return .unspecified
        case .tangemPayAddFundsWithdrawRework: return .unspecified
        case .swapHideZeroBalanceSource: return .unspecified
        case .onrampPaymentMethodThemedImages: return .unspecified
        case .chooseTokenPulseAnimation: return .unspecified
        case .hotWalletDexRatesUntilDeposit: return .unspecified
        case .polymarket: return .unspecified
        case .mobileWalletBackup: return .unspecified
        case .swapDeeplinkParameters: return .unspecified
        case .walletCardsBackupReport: return .unspecified
        case .jointAccounts: return .unspecified
        case .ethPolLocalStakingValidation: return .unspecified
        case .yieldDexTransferDetection: return .unspecified
        case .tangemPayCashback: return .version("6.3")
        case .swapChooseTokenWholeAreaTap: return .unspecified
        case .welcomeScreenV2: return .unspecified
        case .tangemPayPlastic: return .unspecified
        case .gachaMachine: return .unspecified
        case .openTelemetryMetrics: return .unspecified
        case .expressGeoRestrictions: return .unspecified
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

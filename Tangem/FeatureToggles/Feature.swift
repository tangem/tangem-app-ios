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
    case usdtRevokeGaslessFee
    case transactionHistoryV2
    case mobileWalletMultiCreation
    case stakingFlowV2
    case priceAlertsSubscription
    case backup4cards
    case backendAuthentication
    case polymarket
    case walletCardsBackupReport
    case jointAccounts
    case ethPolLocalStakingValidation
    case yieldDexTransferDetection
    case welcomeScreenV2
    case newShtorkaEnabled
    case collectibles
    case openTelemetryMetrics
    case totalTokenBalanceV2
    case expressGeoRestrictions
    case mobileSocialLogin
    case tangemPayOfframp
    case realAssets
    case storiesV2
    case hardwareUpgradeStories
    case jointAccountsGaslessTokenFee
    case tronGaslessActivation
    case merklIncentives
    case tangemPayCustomCards
    case mcp
    case tangemPayChooseCountry
    case payBundleIntroduction
    case hideMarketingBannersWithSystem

    /// Feature toggle `name` format: `TWI-XXX_description_snake_case` or `IOS-XXX_description_snake_case`.
    /// Use the `IOS-` prefix when the toggle has no TWI ticket or tracks a decomposed sub-task of one.
    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .visa: return "Visa"
        case .exchangeOnlyWithinSingleAddress: return "Filter by `exchangeOnlyWithinSingleAddress`"
        case .walletConnectBitcoin: return "WalletConnect Bitcoin"
        case .usdtRevokeGaslessFee: return "USDT Revoke Gasless Fee"
        case .transactionHistoryV2: return "139_Transaction_History_V2"
        case .mobileWalletMultiCreation: return "14278_Mobile_wallet_multi_creation"
        case .stakingFlowV2: return "[REDACTED_INFO]_staking_flow_v2"
        case .priceAlertsSubscription: return "TWI-1603_price_alerts_subscription"
        case .backup4cards: return "[REDACTED_INFO]_backup_4_cards_fw8"
        case .backendAuthentication: return "[REDACTED_INFO]_backend_authentication"
        case .polymarket: return "TWI-1576_polymarket"
        case .walletCardsBackupReport: return "[REDACTED_INFO]_cardlinked_status_update_stage2"
        case .jointAccounts: return "TWI-1611_joint_accounts"
        case .ethPolLocalStakingValidation: return "[REDACTED_INFO]_eth_pol_local_staking_validation"
        case .yieldDexTransferDetection: return "[REDACTED_INFO]_yield_dex_transfer_detection"
        case .welcomeScreenV2: return "TWI-1747_welcome_screen_v2"
        case .newShtorkaEnabled: return "TWI-1608_new_shtorka_enabled"
        case .collectibles: return "TWI-1640_gacha_machine"
        case .openTelemetryMetrics: return "TWI-1627_opentelemetry_metrics_mirroring"
        case .totalTokenBalanceV2: return "[REDACTED_INFO]_total_token_balance_v2"
        case .expressGeoRestrictions: return "[REDACTED_INFO]_express_geo_restrictions"
        case .mobileSocialLogin: return "[REDACTED_INFO]_mobile_social_login"
        case .tangemPayOfframp: return "TWI-1632_tangem_pay_offramp"
        case .realAssets: return "TWI-1477_real_assets_shelf"
        case .storiesV2: return "TWI-1713_stories_v2"
        case .hardwareUpgradeStories: return "TWI-1357_hardware_upgrade_stories"
        case .jointAccountsGaslessTokenFee: return "[REDACTED_INFO]_joint_accounts_gasless_token_fee"
        case .tronGaslessActivation: return "[REDACTED_INFO]_tron_gasless_activation"
        case .merklIncentives: return "TWI-1520_merkl_incentives"
        case .tangemPayCustomCards: return "TWI-1727_tangem_pay_custom_cards"
        case .mcp: return "TWI-1721_mcp"
        case .tangemPayChooseCountry: return "TWI-1771_choose_country"
        case .payBundleIntroduction: return "TWI-1728_pay_bundle_introduction"
        case .hideMarketingBannersWithSystem: return "TWI-1841_hide_marketing_banners_while_system"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .visa: return .unspecified
        case .exchangeOnlyWithinSingleAddress: return .unspecified
        case .walletConnectBitcoin: return .unspecified
        case .usdtRevokeGaslessFee: return .unspecified
        case .transactionHistoryV2: return .version("6.4")
        case .mobileWalletMultiCreation: return .unspecified
        case .stakingFlowV2: return .version("6.4")
        case .priceAlertsSubscription: return .unspecified
        case .backup4cards: return .unspecified
        case .backendAuthentication: return .version("6.4")
        case .polymarket: return .unspecified
        case .walletCardsBackupReport: return .unspecified
        case .jointAccounts: return .unspecified
        case .ethPolLocalStakingValidation: return .unspecified
        case .yieldDexTransferDetection: return .unspecified
        case .welcomeScreenV2: return .version("6.4")
        case .newShtorkaEnabled: return .version("6.4")
        case .collectibles: return .unspecified
        case .openTelemetryMetrics: return .version("6.4")
        case .totalTokenBalanceV2: return .unspecified
        case .expressGeoRestrictions: return .version("6.4")
        case .mobileSocialLogin: return .unspecified
        case .tangemPayOfframp: return .version("6.4")
        case .realAssets: return .unspecified
        case .storiesV2: return .version("6.4")
        case .hardwareUpgradeStories: return .unspecified
        case .jointAccountsGaslessTokenFee: return .unspecified
        case .tronGaslessActivation: return .unspecified
        case .merklIncentives: return .unspecified
        case .tangemPayCustomCards: return .version("6.4")
        case .mcp: return .unspecified
        case .tangemPayChooseCountry: return .version("6.5")
        case .payBundleIntroduction: return .unspecified
        case .hideMarketingBannersWithSystem: return .unspecified
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

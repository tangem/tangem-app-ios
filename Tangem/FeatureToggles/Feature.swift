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
    case mobileWalletMultiCreation
    case priceAlertsSubscription
    case backup4cards
    case polymarket
    case walletCardsBackupReport
    case jointAccounts
    case ethPolLocalStakingValidation
    case yieldDexTransferDetection
    case collectibles
    case totalTokenBalanceV2
    case mobileSocialLogin
    case realAssets
    case hardwareUpgradeStories
    case jointAccountsGaslessTokenFee
    case merklIncentives
    case mcp
    case tangemPayChooseCountry
    case payBundleIntroduction
    case hideMarketingBannersWithSystem
    case tangemPayOnrampV2
    case promoCampaignsV2
    case tangemPayAppleWalletProvisioning
    case customSlippage
    case tronGaslessCEX

    /// Feature toggle `name` format: `TWI-XXX_description_snake_case` or `IOS-XXX_description_snake_case`.
    /// Use the `IOS-` prefix when the toggle has no TWI ticket or tracks a decomposed sub-task of one.
    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .visa: return "Visa"
        case .exchangeOnlyWithinSingleAddress: return "Filter by `exchangeOnlyWithinSingleAddress`"
        case .walletConnectBitcoin: return "WalletConnect Bitcoin"
        case .usdtRevokeGaslessFee: return "USDT Revoke Gasless Fee"
        case .mobileWalletMultiCreation: return "14278_Mobile_wallet_multi_creation"
        case .priceAlertsSubscription: return "TWI-1603_price_alerts_subscription"
        case .backup4cards: return "[REDACTED_INFO]_backup_4_cards_fw8"
        case .polymarket: return "TWI-1576_polymarket"
        case .walletCardsBackupReport: return "[REDACTED_INFO]_cardlinked_status_update_stage2"
        case .jointAccounts: return "TWI-1611_joint_accounts"
        case .ethPolLocalStakingValidation: return "[REDACTED_INFO]_eth_pol_local_staking_validation"
        case .yieldDexTransferDetection: return "[REDACTED_INFO]_yield_dex_transfer_detection"
        case .collectibles: return "TWI-1640_gacha_machine"
        case .totalTokenBalanceV2: return "[REDACTED_INFO]_total_token_balance_v2"
        case .mobileSocialLogin: return "[REDACTED_INFO]_mobile_social_login"
        case .realAssets: return "TWI-1477_real_assets_shelf"
        case .hardwareUpgradeStories: return "TWI-1357_hardware_upgrade_stories"
        case .jointAccountsGaslessTokenFee: return "[REDACTED_INFO]_joint_accounts_gasless_token_fee"
        case .merklIncentives: return "TWI-1520_merkl_incentives"
        case .mcp: return "TWI-1721_mcp"
        case .tangemPayChooseCountry: return "TWI-1771_choose_country"
        case .payBundleIntroduction: return "TWI-1728_pay_bundle_introduction"
        case .hideMarketingBannersWithSystem: return "TWI-1841_hide_marketing_banners_while_system"
        case .tangemPayOnrampV2: return "TWI-1753_tangem_pay_onramp_v2"
        case .promoCampaignsV2: return "TWI-1705_promo_campaigns_v2"
        case .tangemPayAppleWalletProvisioning: return "TWI-1062_apple_wallet_push_provisioning"
        case .customSlippage: return "TWI-1674_custom_slippage"
        case .tronGaslessCEX: return "TWI-1803_tron_gasless_cex"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .visa: return .unspecified
        case .exchangeOnlyWithinSingleAddress: return .unspecified
        case .walletConnectBitcoin: return .unspecified
        case .usdtRevokeGaslessFee: return .unspecified
        case .mobileWalletMultiCreation: return .unspecified
        case .priceAlertsSubscription: return .unspecified
        case .backup4cards: return .unspecified
        case .polymarket: return .unspecified
        case .walletCardsBackupReport: return .unspecified
        case .jointAccounts: return .unspecified
        case .ethPolLocalStakingValidation: return .unspecified
        case .yieldDexTransferDetection: return .unspecified
        case .collectibles: return .unspecified
        case .totalTokenBalanceV2: return .unspecified
        case .mobileSocialLogin: return .unspecified
        case .realAssets: return .unspecified
        case .hardwareUpgradeStories: return .version("6.5")
        case .jointAccountsGaslessTokenFee: return .unspecified
        case .merklIncentives: return .version("6.5")
        case .mcp: return .unspecified
        case .tangemPayChooseCountry: return .version("6.5")
        case .payBundleIntroduction: return .unspecified
        case .hideMarketingBannersWithSystem: return .version("6.5")
        case .tangemPayOnrampV2: return .version("6.5")
        case .promoCampaignsV2: return .version("6.5")
        case .tangemPayAppleWalletProvisioning: return .version("6.5")
        case .customSlippage: return .version("6.5")
        case .tronGaslessCEX: return .unspecified
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

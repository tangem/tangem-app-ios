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
    case polymarketPhaseTwo
    case walletCardsBackupReport
    case jointAccounts
    case ethPolLocalStakingValidation
    case collectibles
    case totalTokenBalanceV2
    case mobileSocialLogin
    case jointAccountsGaslessTokenFee
    case merklIncentives
    case mcp
    case payBundleIntroduction
    case tangemPayAppleWalletProvisioning
    case tokenChartAddToPortfolio
    case marketingActivityBinding
    case qrScanDeeplinks
    case yieldModePromo
    case solanaPNFTAndMetaplexCore

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
        case .polymarketPhaseTwo: return "TWI-1700_polymarket_phase_two"
        case .walletCardsBackupReport: return "[REDACTED_INFO]_cardlinked_status_update_stage2"
        case .jointAccounts: return "TWI-1611_joint_accounts"
        case .ethPolLocalStakingValidation: return "[REDACTED_INFO]_eth_pol_local_staking_validation"
        case .collectibles: return "TWI-1640_gacha_machine"
        case .totalTokenBalanceV2: return "[REDACTED_INFO]_total_token_balance_v2"
        case .mobileSocialLogin: return "[REDACTED_INFO]_mobile_social_login"
        case .jointAccountsGaslessTokenFee: return "[REDACTED_INFO]_joint_accounts_gasless_token_fee"
        case .merklIncentives: return "TWI-1520_merkl_incentives"
        case .mcp: return "TWI-1721_mcp"
        case .payBundleIntroduction: return "TWI-1728_pay_bundle_introduction"
        case .tangemPayAppleWalletProvisioning: return "TWI-1062_apple_wallet_push_provisioning"
        case .tokenChartAddToPortfolio: return "TWI-1857_token_chart_add_to_portfolio"
        case .marketingActivityBinding: return "TWI-1732_marketing_activity_binding"
        case .qrScanDeeplinks: return "TWI-1690_qr_scan_deeplinks"
        case .yieldModePromo: return "TWI-1762_yield_mode_promo"
        case .solanaPNFTAndMetaplexCore: return "TWI-1822_solana_pnft_and_metaplex_core"
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
        case .polymarket: return .version("6.6")
        case .polymarketPhaseTwo: return .unspecified
        case .walletCardsBackupReport: return .version("6.6")
        case .jointAccounts: return .unspecified
        case .ethPolLocalStakingValidation: return .unspecified
        case .collectibles: return .unspecified
        case .totalTokenBalanceV2: return .unspecified
        case .mobileSocialLogin: return .unspecified
        case .jointAccountsGaslessTokenFee: return .unspecified
        case .merklIncentives: return .version("6.6")
        case .mcp: return .unspecified
        case .payBundleIntroduction: return .unspecified
        case .tangemPayAppleWalletProvisioning: return .unspecified
        case .tokenChartAddToPortfolio: return .version("6.6")
        case .marketingActivityBinding: return .unspecified
        case .qrScanDeeplinks: return .unspecified
        case .yieldModePromo: return .unspecified
        case .solanaPNFTAndMetaplexCore: return .unspecified
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

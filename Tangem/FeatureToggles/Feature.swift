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
    // When enabling, check signPsbt with other parties' finalized inputs: since bdk-swift 3.1.1 they no longer fail finalization
    case walletConnectBitcoin
    case usdtRevokeGaslessFee
    case mobileWalletMultiCreation
    case priceAlertsSubscription
    case backup4cards
    case polymarketPhaseTwo
    case jointAccounts
    case ethPolLocalStakingValidation
    case collectibles
    case totalTokenBalanceV2
    case mobileSocialLogin
    case jointAccountsGaslessTokenFee
    case tangemPayAppleWalletProvisioning
    case tronGaslessDEX
    case tangemPayMoneyAccount
    case tangemPayCustomerSummary
    case solanaGasless
    case promoPage
    case dogecoinPsbtBdkFeeRateLimit
    case polymarketFastOrders
    case polymarketFastTradingPause
    case allServices
    case intentSurvey
    case onrampCountryByIP
    case lendingOnAave
    case polymarketEventCharts
    case nativeNPSSurvey
    case shtorkaProductDebt

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
        case .polymarketPhaseTwo: return "TWI-1700_polymarket_phase_two"
        case .jointAccounts: return "TWI-1611_joint_accounts"
        case .ethPolLocalStakingValidation: return "[REDACTED_INFO]_eth_pol_local_staking_validation"
        case .collectibles: return "TWI-1640_gacha_machine"
        case .totalTokenBalanceV2: return "[REDACTED_INFO]_total_token_balance_v2"
        case .mobileSocialLogin: return "[REDACTED_INFO]_mobile_social_login"
        case .jointAccountsGaslessTokenFee: return "[REDACTED_INFO]_joint_accounts_gasless_token_fee"
        case .tangemPayAppleWalletProvisioning: return "TWI-1062_apple_wallet_push_provisioning"
        case .tronGaslessDEX: return "TWI-1850_tron_gasless_dex"
        case .tangemPayMoneyAccount: return "TWI-1525_money_account"
        case .tangemPayCustomerSummary: return "[REDACTED_INFO]_tangem_pay_customer_summary"
        case .solanaGasless: return "TWI-1258_solana_gasless"
        case .promoPage: return "[REDACTED_INFO]_promo_page"
        case .dogecoinPsbtBdkFeeRateLimit: return "[REDACTED_INFO]_dogecoin_psbt_bdk_fee_rate_limit"
        case .polymarketFastOrders: return "TWI-1881_polymarket_fast_orders"
        case .polymarketFastTradingPause: return "[REDACTED_INFO]_polymarket_fast_trading_pause"
        case .allServices: return "TWI-1720_all_services"
        case .intentSurvey: return "TWI-1899_intent_survey"
        case .onrampCountryByIP: return "[REDACTED_INFO]_onramp_country_by_ip"
        case .lendingOnAave: return "TWI-1676_lending_on_aave"
        case .polymarketEventCharts: return "TWI-1912_polymarket_event_charts"
        case .nativeNPSSurvey: return "TWI-1898_native_nps_survey"
        case .shtorkaProductDebt: return "TWI-1910_shtorka_product_debt"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .visa: return .unspecified
        case .exchangeOnlyWithinSingleAddress: return .unspecified
        case .walletConnectBitcoin: return .unspecified
        case .usdtRevokeGaslessFee: return .unspecified
        case .mobileWalletMultiCreation: return .version("6.9")
        case .priceAlertsSubscription: return .unspecified
        case .backup4cards: return .unspecified
        case .polymarketPhaseTwo: return .unspecified
        case .jointAccounts: return .unspecified
        case .ethPolLocalStakingValidation: return .unspecified
        case .collectibles: return .unspecified
        case .totalTokenBalanceV2: return .unspecified
        case .mobileSocialLogin: return .unspecified
        case .jointAccountsGaslessTokenFee: return .unspecified
        case .tangemPayAppleWalletProvisioning: return .unspecified
        case .tronGaslessDEX: return .version("6.9")
        case .tangemPayMoneyAccount: return .unspecified
        case .tangemPayCustomerSummary: return .unspecified
        case .solanaGasless: return .unspecified
        case .promoPage: return .version("6.9")
        case .dogecoinPsbtBdkFeeRateLimit: return .version("6.9")
        case .polymarketFastOrders: return .unspecified
        case .polymarketFastTradingPause: return .unspecified
        case .allServices: return .unspecified
        case .intentSurvey: return .unspecified
        case .onrampCountryByIP: return .unspecified
        case .lendingOnAave: return .unspecified
        case .polymarketEventCharts: return .unspecified
        case .nativeNPSSurvey: return .unspecified
        case .shtorkaProductDebt: return .unspecified
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

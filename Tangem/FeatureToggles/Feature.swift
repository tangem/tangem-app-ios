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
    case marketsAndNews
    case marketsEarn
    case exchangeOnlyWithinSingleAddress
    case experimentService
    case walletConnectBitcoin
    case expressFixedRates
    case mainQRScan
    case customerIO
    case surveySparrow
    case mobileWalletTokenAutoSync
    case gaslessDexAndApprove
    case solanaTxHistoryEnabled
    case solanaScaledUIEnabled
    case dynamicAddresses
    case usdtRevokeGaslessFee
    case newPromotionBanners

    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .visa: return "Visa"
        case .redesign: return "Redesign"
        case .marketsAndNews: return "Markets & News"
        case .marketsEarn: return "Markets Earn"
        case .exchangeOnlyWithinSingleAddress: return "Filter by `exchangeOnlyWithinSingleAddress`"
        case .experimentService: return "Experiment service"
        case .walletConnectBitcoin: return "WalletConnect Bitcoin"
        case .expressFixedRates: return "Express Fixed Rates"
        case .mainQRScan: return "Main QR Scan"
        case .customerIO: return "customer.io service integration"
        case .surveySparrow: return "SurveySparrow service integration"
        case .mobileWalletTokenAutoSync: return "Wallet Token Auto Sync"
        case .gaslessDexAndApprove: return "Gasless Fees For Dex and Approve"
        case .solanaTxHistoryEnabled: return "Solana Transaction History"
        case .solanaScaledUIEnabled: return "Solana Scaled UI"
        case .dynamicAddresses: return "XPUB Dynamic-addresses support"
        case .usdtRevokeGaslessFee: return "USDT Revoke Gasless Fee"
        case .newPromotionBanners: return "New Promotion Banners"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .visa: return .unspecified
        case .redesign: return .unspecified
        case .marketsAndNews: return .version("5.33")
        case .marketsEarn: return .version("5.35")
        case .exchangeOnlyWithinSingleAddress: return .unspecified
        case .experimentService: return .unspecified
        case .walletConnectBitcoin: return .unspecified
        case .expressFixedRates: return .version("5.37")
        case .mainQRScan: return .version("5.36")
        case .customerIO: return .version("5.35")
        case .surveySparrow: return .unspecified
        case .mobileWalletTokenAutoSync: return .unspecified
        case .gaslessDexAndApprove: return .version("5.37")
        case .solanaTxHistoryEnabled: return .unspecified
        case .solanaScaledUIEnabled: return .unspecified
        case .dynamicAddresses: return .unspecified
        case .usdtRevokeGaslessFee: return .unspecified
        case .newPromotionBanners: return .version("5.37")
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

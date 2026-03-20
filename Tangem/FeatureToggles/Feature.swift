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
    case accounts
    case redesign
    case marketsAndNews
    case marketsEarn
    case exchangeOnlyWithinSingleAddress
    case experimentService
    case expressFixedRates
    case mainQRScan
    case customerIO
    case mobileWalletTokenAutoSync

    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .visa: return "Visa"
        case .accounts: return "Accounts"
        case .redesign: return "Redesign"
        case .marketsAndNews: return "Markets & News"
        case .marketsEarn: return "Markets Earn"
        case .exchangeOnlyWithinSingleAddress: return "Filter by `exchangeOnlyWithinSingleAddress`"
        case .experimentService: return "Experiment service"
        case .expressFixedRates: return "Express Fixed Rates"
        case .mainQRScan: return "Main QR Scan"
        case .customerIO: return "customer.io service integration"
        case .mobileWalletTokenAutoSync: return "Wallet Token Auto Sync"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .visa: return .unspecified
        case .accounts: return .version("5.33")
        case .redesign: return .unspecified
        case .marketsAndNews: return .version("5.33")
        case .marketsEarn: return .version("5.35")
        case .exchangeOnlyWithinSingleAddress: return .unspecified
        case .experimentService: return .unspecified
        case .expressFixedRates: return .unspecified
        case .mainQRScan: return .version("5.36")
        case .customerIO: return .version("5.35")
        case .mobileWalletTokenAutoSync: return .unspecified
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

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
    case learnToEarn
    case visa // [REDACTED_TODO_COMMENT]
    case accounts
    case marketsAndNews
    case marketsEarn
    case tangemPayPermanentEntryPoint
    case gaslessTransactions
    case exchangeOnlyWithinSingleAddress
    case experimentService

    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .learnToEarn: return "Learn to Earn"
        case .visa: return "Visa"
        case .accounts: return "Accounts"
        case .marketsAndNews: return "Markets & News"
        case .marketsEarn: return "Markets Earn"
        case .tangemPayPermanentEntryPoint: return "TangemPay Permanent Entry Point"
        case .gaslessTransactions: return "Gasless transactions"
        case .exchangeOnlyWithinSingleAddress: return "Filter by `exchangeOnlyWithinSingleAddress`"
        case .experimentService: return "Experiment service"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .learnToEarn: return .unspecified
        case .visa: return .unspecified
        case .accounts: return .version("5.33")
        case .marketsAndNews: return .version("5.33")
        case .marketsEarn: return .unspecified
        case .tangemPayPermanentEntryPoint: return .version("5.33")
        case .gaslessTransactions: return .version("5.33")
        case .exchangeOnlyWithinSingleAddress: return .unspecified
        case .experimentService: return .unspecified
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

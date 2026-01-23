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
    case mobileWallet
    case wcSolanaALT
    case accounts
    case marketsAndNews
    case marketsEarn
    case tangemPayPermanentEntryPoint
    case gaslessTransactions

    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .learnToEarn: return "Learn to Earn"
        case .visa: return "Visa"
        case .mobileWallet: return "Mobile wallet"
        case .wcSolanaALT: return "WalletConnect Solana ALT"
        case .accounts: return "Accounts"
        case .marketsAndNews: return "Markets & News"
        case .marketsEarn: return "Markets Earn"
        case .tangemPayPermanentEntryPoint: return "TangemPay Permanent Entry Point"
        case .gaslessTransactions: return "Gasless transactions"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .learnToEarn: return .unspecified
        case .visa: return .version("5.31")
        case .mobileWallet: return .version("5.32")
        case .wcSolanaALT: return .version("5.28")
        case .accounts: return .version("5.33")
        case .marketsAndNews: return .unspecified
        case .marketsEarn: return .unspecified
        case .tangemPayPermanentEntryPoint: return .unspecified
        case .gaslessTransactions: return .unspecified
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

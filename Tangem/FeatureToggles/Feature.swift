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
    case logs
    case mobileWallet
    case deeplink
    case wcSolanaALT
    case accounts
    case receiveENS
    case newOnrampUI

    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .learnToEarn: return "Learn to Earn"
        case .visa: return "Visa"
        case .logs: return "Logs"
        case .mobileWallet: return "Mobile wallet"
        case .deeplink: return "Deeplink"
        case .wcSolanaALT: return "WalletConnect Solana ALT"
        case .accounts: return "Accounts"
        case .receiveENS: return "Receive (ENS)"
        case .newOnrampUI: return "Onramp on new UI"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .learnToEarn: return .unspecified
        case .visa: return .unspecified
        case .logs: return .version("5.25")
        case .mobileWallet: return .unspecified
        case .deeplink: return .version("5.25")
        case .wcSolanaALT: return .version("5.28")
        case .accounts: return .unspecified
        case .receiveENS: return .version("5.28")
        case .newOnrampUI: return .unspecified
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

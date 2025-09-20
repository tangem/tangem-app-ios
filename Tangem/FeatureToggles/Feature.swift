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
    case nft
    case logs
    case sendViaSwap
    case mobileWallet
    case pushTransactionNotifications
    case deeplink
    case wcSolanaALT
    case accounts
    case nftNewSendUI
    case receiveENS
    case sellNewSendUI
    case newOnrampUI
    case pushPermissionNotificationBanner

    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .learnToEarn: return "Learn to Earn"
        case .visa: return "Visa"
        case .nft: return "NFT"
        case .logs: return "Logs"
        case .sendViaSwap: return "Send via Swap"
        case .mobileWallet: return "Mobile wallet"
        case .pushTransactionNotifications: return "Push Transaction Notifications"
        case .deeplink: return "Deeplink"
        case .wcSolanaALT: return "WalletConnect Solana ALT"
        case .accounts: return "Accounts"
        case .nftNewSendUI: return "NFT New Send UI"
        case .receiveENS: return "Receive (ENS)"
        case .sellNewSendUI: return "Sell on New Send UI"
        case .newOnrampUI: return "Onramp on new UI"
        case .pushPermissionNotificationBanner: return "Push Permission Notification Banner"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .learnToEarn: return .unspecified
        case .visa: return .unspecified
        case .nft: return .version("5.25")
        case .logs: return .version("5.25")
        case .sendViaSwap: return .version("5.28")
        case .mobileWallet: return .unspecified
        case .pushTransactionNotifications: return .version("5.26.3")
        case .deeplink: return .version("5.25")
        case .wcSolanaALT: return .version("5.28")
        case .accounts: return .unspecified
        case .nftNewSendUI: return .version("5.28")
        case .receiveENS: return .version("5.28")
        case .sellNewSendUI: return .version("5.29")
        case .newOnrampUI: return .unspecified
        case .pushPermissionNotificationBanner: return .unspecified
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

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
    case onramp
    case visa // [REDACTED_TODO_COMMENT]
    case nft
    case walletConnectUI
    case logs
    case newSendUI
    case sendViaSwap
    case hotWallet
    case pushTransactionNotifications
    case deeplink

    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .learnToEarn: return "Learn to Earn"
        case .onramp: return "Onramp"
        case .visa: return "Visa"
        case .nft: return "NFT"
        case .walletConnectUI: return "WalletConnect UI"
        case .logs: return "Logs"
        case .newSendUI: return "New Send UI"
        case .sendViaSwap: return "Send via Swap"
        case .hotWallet: return "Hot wallet"
        case .pushTransactionNotifications: return "Push Transaction Notifications"
        case .deeplink: return "Deeplink"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .learnToEarn: return .unspecified
        case .onramp: return .version("5.24.2")
        case .visa: return .unspecified
        case .nft: return .version("5.25")
        case .walletConnectUI: return .unspecified
        case .logs: return .version("5.25")
        case .newSendUI: return .unspecified
        case .sendViaSwap: return .unspecified
        case .hotWallet: return .unspecified
        case .pushTransactionNotifications: return .version("5.26.3")
        case .deeplink: return .version("5.25")
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

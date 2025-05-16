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
    case newAttestation

    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .learnToEarn: return "Learn to Earn"
        case .onramp: return "Onramp"
        case .visa: return "Visa"
        case .nft: return "NFT"
        case .walletConnectUI: return "WalletConnect UI"
        case .newAttestation: return "New Attestation"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .learnToEarn: return .unspecified
        case .onramp: return .version("5.24")
        case .visa: return .unspecified
        case .nft: return .unspecified
        case .walletConnectUI: return .unspecified
        case .newAttestation: return .unspecified
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

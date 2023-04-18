//
//  FeatureToggle.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum FeatureToggle: String, Hashable, CaseIterable {
    case exchange
    case referralProgram
    case walletConnectV2
    case blockBookUtxoApis
    case importSeedPhrase
    case accessCodeRecoverySettings

    var name: String {
        switch self {
        case .exchange: return "Exchange"
        case .referralProgram: return "Referral Program"
        case .walletConnectV2: return "WalletConnect V2"
        case .blockBookUtxoApis: return "Block Book UTXO APIs (NOWNodes, GetBlock)"
        case .importSeedPhrase: return "Import seed phrase (Firmware 6.11 and above)"
        case .accessCodeRecoverySettings: return "Access Code Recovery Settings"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .exchange: return .version("4.2")
        case .referralProgram: return .version("4.2")
        case .walletConnectV2: return .unspecified
        case .blockBookUtxoApis: return .version("4.3")
        case .importSeedPhrase: return .unspecified
        case .accessCodeRecoverySettings: return .unspecified
        }
    }
}

extension FeatureToggle {
    enum ReleaseVersion: Hashable {
        /// This case is for an unterminated release date
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

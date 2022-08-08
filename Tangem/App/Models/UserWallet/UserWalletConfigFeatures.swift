//
//  UserWalletConfigFeatures.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum UserWalletFeature: Int {
    case accessCode
    case passcode
    case signing
    case longHashes
    case signedHashesCounter
    case backup
    case twinning
    case sendingToPayID
    case exchange
    case walletConnect
    case manageTokens
    case activation
    case tokensSearch
    case resetToFactory
    case showAddress
    case withdrawal
}

extension UserWalletFeature {
    enum Availability {
        case available
        case unavailable
        case disabled(localizedReason: String? = nil)

        var disabledLocalizedReason: String? {
            if case let .disabled(reason) = self, let reason = reason {
                return reason
            }

            return nil
        }

        var isAvailable: Bool {
            if case .available = self {
                return true
            }

            return false
        }

        var isHidden: Bool {
            if case .unavailable = self {
                return true
            }

            return false
        }
    }
}

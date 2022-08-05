//
//  UserWalletConfigFeatures.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum UserWalletFeature: Int {
    case none

    // MARK: - Card features

    case settingAccessCodeAllowed
    case settingPasscodeAllowed
    case signingSupported
    case longHashesSupported
    case signedHashesCounterAvailable
    case backup
    case twinning

    // MARK: - App features

    case sendingToPayIDAllowed
    case exchangingAllowed
    case walletConnectAllowed
    case manageTokensAllowed
    case activation
    case tokensSearch
}

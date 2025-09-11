//
//  YieldModuleViewParams.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

enum YieldModuleViewParams {
    struct StartEarningParams: Equatable {
        let tokenName: String
        let tokenIcon: Image
        let networkFee: String
        let maximumFee: String
        let blockchainName: String
    }

    struct RateInfoParams: Equatable {
        let lastYearReturns: [String: Double]
    }

    struct FeePolicyParams: Equatable {
        let currentFee: String
        let maximumFee: String
        let tokenName: String
        let blockchainName: String
    }
}

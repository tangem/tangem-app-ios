//
//  RateAppService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol RateAppService {
    func registerBalances(of walletModels: [WalletModel])
    func requestRateAppIfAvailable(with request: RateAppRequest)
}

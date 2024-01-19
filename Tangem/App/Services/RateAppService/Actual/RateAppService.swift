//
//  RateAppService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol RateAppService {
    var rateAppAction: AnyPublisher<RateAppAction, Never> { get }

    func registerBalances(of walletModels: [WalletModel])
    func requestRateAppIfAvailable(with request: RateAppRequest)
    func respondToRateAppDialog(with response: RateAppResponse)
}

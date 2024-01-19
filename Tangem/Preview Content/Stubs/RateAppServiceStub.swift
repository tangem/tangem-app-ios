//
//  RateAppServiceStub.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct RateAppServiceStub: RateAppService {
    var rateAppAction: AnyPublisher<RateAppAction, Never> { .just(output: .openAppRateDialog) }

    func registerBalances(of walletModels: [WalletModel]) {}
    func requestRateAppIfAvailable(with request: RateAppRequest) {}
    func respondToRateAppDialog(with response: RateAppResponse) {}
}

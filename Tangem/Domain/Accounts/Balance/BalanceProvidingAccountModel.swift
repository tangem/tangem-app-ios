//
//  BalanceProvidingAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol BalanceProvidingAccountModel {
    var fiatTotalBalanceProvider: AccountBalanceProvider { get }
    var rateProvider: AccountRateProvider { get }
}

extension BalanceProvidingAccountModel {
    var formattedBalanceTypePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never> {
        fiatTotalBalanceProvider.formattedBalanceTypePublisher
            .receiveOnMain()
            .map { balanceType in
                return LoadableTokenBalanceViewStateBuilder().build(type: balanceType)
            }
            .eraseToAnyPublisher()
    }
}

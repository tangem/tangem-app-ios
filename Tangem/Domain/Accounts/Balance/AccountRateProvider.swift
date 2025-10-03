//
//  AccountRateProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol AccountRateProvider {
    typealias AccountRate = RateValue<AccountQuote>

    var accountRate: AccountRate { get }
    var accountRatePublisher: AnyPublisher<AccountRate, Never> { get }
}

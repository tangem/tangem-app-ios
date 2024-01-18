//
//  TotalBalanceProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

protocol TotalBalanceProviding {
    var totalBalancePublisher: AnyPublisher<LoadingValue<TotalBalance>, Never> { get }
}

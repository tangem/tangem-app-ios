//
//  AccountModelsSelector.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

typealias BaseAccountModelsSelector = any AccountModelsSelector<[any BaseAccountModel]>

/// What an `AccountModelsAggregator` takes out of a wallet's account list. `Models` is the answer's own shape: a list
/// for the kinds a wallet may hold several of, an optional for the kinds it holds at most one of.
protocol AccountModelsSelector<Models> {
    associatedtype Models

    func select(from accountModels: [AccountModel]) -> Models
    func selectedPublisher(from accountModelsPublisher: AnyPublisher<[AccountModel], Never>) -> AnyPublisher<Models, Never>
}

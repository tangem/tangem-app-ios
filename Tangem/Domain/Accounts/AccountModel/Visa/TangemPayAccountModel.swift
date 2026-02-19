//
//  TangemPayAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemPay

protocol TangemPayAccountModel {
    var statePublisher: AnyPublisher<TangemPayLocalState, Never> { get }

    var customerId: String? { get }

    func refreshState() async
    func syncTokens(authorizingInteractor: TangemPayAuthorizing, completion: @escaping () -> Void)
}

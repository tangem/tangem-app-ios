//
//  TangemPayAccountProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol TangemPayAccountProvider {
    var tangemPayAccount: TangemPayAccount? { get }
    var tangemPayAccountPublisher: AnyPublisher<TangemPayAccount, Never> { get }
}

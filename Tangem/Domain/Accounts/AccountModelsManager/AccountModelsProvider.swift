//
//  AccountModelsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

/// An outside source of ready-made account models — the Polymarket account today. A kind is provided rather than
/// built when it needs nothing of `CommonAccountModelsManager`'s machinery: no entry in the wallet's account list,
/// no cache and no disposal.
protocol AccountModelsProvider {
    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> { get }
}

//
//  NoopAccountPendingDerivationProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class NoopAccountPendingDerivationProvider: AccountPendingDerivationProvider {
    var pendingDerivationsPublisher: AnyPublisher<[PendingDerivation], Never> { .just(output: []) }
}

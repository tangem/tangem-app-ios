//
//  AccountPendingDerivationProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol AccountPendingDerivationProvider: PendingDerivationStatusProvider {
    var pendingDerivationsPublisher: AnyPublisher<[PendingDerivation], Never> { get }
}

//
//  DerivationStatusProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol DerivationStatusProvider: AnyObject {
    var hasPendingDerivations: AnyPublisher<Bool, Never> { get }
    var pendingDerivationsCount: AnyPublisher<Int, Never> { get }
}

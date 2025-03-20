//
//  DerivationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

protocol DerivationManager {
    var hasPendingDerivations: AnyPublisher<Bool, Never> { get }
    var pendingDerivationsCount: AnyPublisher<Int, Never> { get }

    func deriveKeys(cardInteractor: KeysDeriving, completion: @escaping (Result<Void, TangemSdkError>) -> Void)
}

// [REDACTED_TODO_COMMENT]
protocol DerivationManagerDelegate: AnyObject {
    func onDerived(_ response: DerivationResult)
}

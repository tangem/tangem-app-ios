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

    func needsDerivation(networksToRemove: [BlockchainNetwork], networksToAdd: [BlockchainNetwork], interactor: KeysDeriving) -> Bool
    func deriveKeys(interactor: KeysDeriving, completion: @escaping (Result<Void, Error>) -> Void)
}

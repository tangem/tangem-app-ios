//
//  KeysDerivingInteractorFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

/// Mints a fresh interactor from the live `UserWalletModel` on every call.
/// Long-lived holders must retain this factory instead of a `KeysDeriving` instance,
/// otherwise the interactor freezes the session filter and SDK configuration it was created with.
final class KeysDerivingInteractorFactory {
    private weak var userWalletModel: (any UserWalletModel)?

    init(userWalletModel: (any UserWalletModel)? = nil) {
        self.userWalletModel = userWalletModel
    }

    func configure(with userWalletModel: any UserWalletModel) {
        self.userWalletModel = userWalletModel
    }

    func makeInteractor() -> KeysDeriving {
        userWalletModel?.keysDerivingInteractor ?? DeallocatedUserWalletModelKeysDeriving()
    }
}

// MARK: - Fallback stub

private final class DeallocatedUserWalletModelKeysDeriving: KeysDeriving {
    var requiresCard: Bool { false }

    func deriveKeys(derivations: [Data: [DerivationPath]], completion: @escaping (Result<DerivationResult, Error>) -> Void) {
        completion(.failure("UserWalletModel is deallocated, keys deriving is unavailable"))
    }
}

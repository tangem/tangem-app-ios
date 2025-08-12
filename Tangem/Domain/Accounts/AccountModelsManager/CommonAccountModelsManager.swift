//
//  CommonAccountModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class CommonAccountModelsManager {}

// MARK: - AccountModelsManager protocol conformance

extension CommonAccountModelsManager: AccountModelsManager {
    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    func addCryptoAccount() async throws -> CryptoAccountModel {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    func archiveCryptoAccount(with index: Int) async throws -> CryptoAccountModel {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }
}

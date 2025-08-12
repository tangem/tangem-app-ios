//
//  AccountModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// [REDACTED_TODO_COMMENT]
protocol AccountModelsManager {
    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> { get }

    /// - Note: This method is also responsible for moving custom tokens into the newly created account if they have a matching derivation.
    /// - Returns: The created account model.
    @discardableResult
    func addCryptoAccount() async throws -> CryptoAccountModel

    /// - Returns: The archived account model.
    @discardableResult
    func archiveCryptoAccount(with index: Int) async throws -> CryptoAccountModel
}

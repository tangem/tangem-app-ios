//
//  DummyCommonAccountModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Just a stub when there should be no accounts available (locked wallets, feature toggle is disabled, etc).
struct DummyCommonAccountModelsManager {}

// MARK: - AccountModelsManager protocol conformance

extension DummyCommonAccountModelsManager: AccountModelsManager {
    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        return AnyPublisher.just(output: [])
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws -> any CryptoAccountModel {
        throw CommonError.notImplemented
    }

    func archiveCryptoAccount(with index: Int) async throws -> any CryptoAccountModel {
        throw CommonError.notImplemented
    }
}

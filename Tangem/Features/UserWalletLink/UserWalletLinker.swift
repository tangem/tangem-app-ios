//
//  UserWalletLinker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

protocol UserWalletLinker {
    func isLinkSupported(_ userWalletModel: some UserWalletModel) -> Bool
    nonisolated(nonsending) func link(_ userWalletModel: some UserWalletModel) async throws(UserWalletLinkError)
}

extension UserWalletLinker {
    @discardableResult
    func link(
        _ userWalletModel: some UserWalletModel,
        completion: @escaping (Result<Void, UserWalletLinkError>) -> Void
    ) -> Task<Void, Never> {
        Task { @MainActor in
            do throws(UserWalletLinkError) {
                try await link(userWalletModel)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

enum UserWalletLinkError: Error {
    case cancelled
    case notSupported
    case failed(stage: UserWalletLinkStage, underlying: any Error)
}

enum UserWalletLinkStage {
    case nonce
    case prepare
    case submit
    case register
}

// MARK: - Dependency injection

private struct UserWalletLinkerKey: InjectionKey {
    static var currentValue: UserWalletLinker = CommonUserWalletLinker()
}

extension InjectedValues {
    var userWalletLinker: UserWalletLinker {
        get { Self[UserWalletLinkerKey.self] }
        set { Self[UserWalletLinkerKey.self] = newValue }
    }
}

//
//  KeysDerivingMobileWalletInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletSdk
import TangemSdk
import TangemFoundation

class KeysDerivingMobileWalletInteractor {
    let userWalletId: UserWalletId
    let userWalletConfig: UserWalletConfig

    @Injected(\.sessionMobileAccessCodeStorageManager)
    private var accessCodeStorageManager: MobileAccessCodeStorageManager

    private lazy var accessCodeManager = SessionMobileAccessCodeManager(
        userWalletId: userWalletId,
        configuration: .default,
        storageManager: accessCodeStorageManager
    )

    init(userWalletId: UserWalletId, userWalletConfig: UserWalletConfig) {
        self.userWalletId = userWalletId
        self.userWalletConfig = userWalletConfig
    }
}

// MARK: - KeysDeriving

extension KeysDerivingMobileWalletInteractor: KeysDeriving {
    func deriveKeys(
        derivations: [Data: [DerivationPath]],
        completion: @escaping (Result<DerivationResult, Error>) -> Void
    ) {
        let sdk = CommonMobileWalletSdk()

        runTask(in: self) { interactor in
            do {
                let context = try await interactor.unlock()
                let derived = try sdk.deriveKeys(context: context, derivationPaths: derivations)

                let mapped: DerivationResult = derived.reduce(into: [:]) { partialResult, keyInfo in
                    partialResult[keyInfo.key] = .init(keys: keyInfo.value.derivedKeys)
                }

                completion(.success(mapped))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

private extension KeysDerivingMobileWalletInteractor {
    func unlock() async throws -> MobileWalletContext {
        let authUtil = MobileAuthUtil(
            userWalletId: userWalletId,
            config: userWalletConfig,
            biometricsProvider: CommonUserWalletBiometricsProvider(),
            accessCodeManager: accessCodeManager
        )
        let unlockResult = try await authUtil.unlock()

        return try await handleUnlockResult(unlockResult, userWalletId: userWalletId)
    }

    func handleUnlockResult(
        _ result: MobileAuthUtil.Result,
        userWalletId: UserWalletId
    ) async throws -> MobileWalletContext {
        switch result {
        case .successful(let context):
            return context
        case .canceled, .userWalletNeedsToDelete:
            throw CancellationError()
        }
    }
}

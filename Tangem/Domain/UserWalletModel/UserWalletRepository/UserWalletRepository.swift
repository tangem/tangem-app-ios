//
//  UserWalletRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import LocalAuthentication
import TangemFoundation

protocol UserWalletRepository {
    var shouldLockOnBackground: Bool { get }
    var isLocked: Bool { get }
    var models: [UserWalletModel] { get }
    var selectedModel: UserWalletModel? { get }
    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> { get }

    func initialize() async
    func lock()
    func unlock(with method: UserWalletRepositoryUnlockMethod) async throws -> UserWalletModel
    func select(userWalletId: UserWalletId)
    func updateAssociatedCard(userWalletId: UserWalletId, cardId: String)
    func add(userWalletModel: UserWalletModel) throws
    func delete(userWalletId: UserWalletId)
    func onBiometricsChanged(enabled: Bool)
    func onSaveUserWalletsChanged(enabled: Bool)
    func savePublicData()
    func save(userWalletModel: UserWalletModel)
}

extension UserWalletRepository {
    /// User has only one wallet is app
    var hasOnlyOneWallet: Bool {
        models.count == 1
    }
}

private struct UserWalletRepositoryKey: InjectionKey {
    static var currentValue: UserWalletRepository = CommonUserWalletRepository()
}

extension InjectedValues {
    var userWalletRepository: UserWalletRepository {
        get { Self[UserWalletRepositoryKey.self] }
        set { Self[UserWalletRepositoryKey.self] = newValue }
    }
}

enum UserWalletRepositoryEvent: Equatable {
    case locked
    case unlocked
    case inserted(userWalletId: UserWalletId)
    case unlockedWallet(userWalletId: UserWalletId)
    case deleted(userWalletIds: [UserWalletId], isRepositoryEmpty: Bool)
    case selected(userWalletId: UserWalletId)
}

enum UserWalletRepositoryUnlockMethod {
    case biometrics(LAContext)
    case biometricsUserWallet(userWalletId: UserWalletId, context: LAContext)
    case encryptionKey(userWalletId: UserWalletId, encryptionKey: UserWalletEncryptionKey)

    var analyticsValue: Analytics.ParameterValue {
        switch self {
        case .biometrics, .biometricsUserWallet:
            return Analytics.ParameterValue.signInTypeBiometrics
        case .encryptionKey:
            return Analytics.ParameterValue.card
        }
    }
}

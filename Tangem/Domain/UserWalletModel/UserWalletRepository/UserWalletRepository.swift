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

protocol UserWalletRepository {
    var isLocked: Bool { get }
    var models: [UserWalletModel] { get }
    var selectedModel: UserWalletModel? { get }
    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> { get }

    func initialize() async
    func lock()
    func unlock(with method: UserWalletRepositoryUnlockMethod) throws -> UserWalletModel
    func unlock(userWalletId: UserWalletId, method: UserWalletRepositoryUnlockMethod) throws
    func select(userWalletId: UserWalletId)
    func updateAssociatedCard(userWalletId: UserWalletId, cardId: String)
    func add(userWalletModel: UserWalletModel) throws
    func delete(userWalletId: UserWalletId)
    func onSaveUserWalletsChanged(enabled: Bool)
    func savePublicData()
    func save(userWalletModel: UserWalletModel)
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

enum UserWalletRepositoryEvent {
    case locked
    case unlockedBiometrics
    case inserted(userWalletId: UserWalletId)
    case unlocked(userWalletId: UserWalletId)
    case deleted(userWalletIds: [UserWalletId])
    case selected(userWalletId: UserWalletId)
}

enum UserWalletRepositoryUnlockMethod {
    case biometrics(LAContext)
    case card(CardInfo)
    case mobileWallet(userWalletId: UserWalletId, encryptionKey: UserWalletEncryptionKey)

    var analyticsValue: Analytics.ParameterValue {
        switch self {
        case .biometrics:
            return Analytics.ParameterValue.signInTypeBiometrics
        case .card:
            return Analytics.ParameterValue.card
        case .mobileWallet:
            return Analytics.ParameterValue.accessCode
        }
    }
}

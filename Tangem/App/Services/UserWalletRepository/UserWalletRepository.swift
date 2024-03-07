//
//  UserWalletRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UserWalletRepository: Initializable {
    var hasSavedWallets: Bool { get }
    var models: [UserWalletModel] { get }
    var selectedModel: UserWalletModel? { get }
    var selectedUserWalletId: Data? { get }
    var selectedIndexUserWalletModel: Int? { get }
    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> { get }

    func unlock(with method: UserWalletRepositoryUnlockMethod, completion: @escaping (UserWalletRepositoryResult?) -> Void)
    func setSelectedUserWalletId(_ userWalletId: Data?, unlockIfNeeded: Bool, reason: UserWalletRepositorySelectionChangeReason)
    func updateSelection()
    func logoutIfNeeded()
    func add(_ userWalletModel: UserWalletModel)
    func delete(_ userWalletId: UserWalletId, logoutIfNeeded shouldAutoLogout: Bool)
    func save()
    func clearNonSelectedUserWallets()
    func initializeServices(for userWalletModel: UserWalletModel)
    func initialClean()
    func setSaving(_ enabled: Bool)
    func addOrScan(completion: @escaping (UserWalletRepositoryResult?) -> Void)
}

extension UserWalletRepository {
    /// Selecting UserWallet with specified Id and unlocking it if needed
    func setSelectedUserWalletId(_ userWalletId: Data?, reason: UserWalletRepositorySelectionChangeReason) {
        setSelectedUserWalletId(userWalletId, unlockIfNeeded: true, reason: reason)
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

enum UserWalletRepositoryResult {
    case success(UserWalletModel)
    case onboarding(OnboardingInput)
    case troubleshooting
    case error(Error)
    case partial(UserWalletModel, Error)

    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }
}

enum UserWalletRepositoryEvent {
    case locked(reason: UserWalletRepositoryLockReason)
    case biometryUnlocked
    case scan(isScanning: Bool)
    case inserted(userWalletId: UserWalletId)
    case updated(userWalletId: UserWalletId)
    case deleted(userWalletIds: [UserWalletId])
    case selected(userWalletId: UserWalletId, reason: UserWalletRepositorySelectionChangeReason)
    case replaced(userWalletId: UserWalletId)
}

enum UserWalletRepositorySelectionChangeReason {
    case userSelected
    case inserted
    case deleted
}

enum UserWalletRepositoryLockReason {
    case loggedOut
    case nothingToDisplay
}

enum UserWalletRepositoryUnlockMethod {
    case biometry
    case card(userWalletId: UserWalletId?)
}

enum UserWalletRepositoryError: String, Error, LocalizedError, BindableError {
    case duplicateWalletAdded
    case biometricsChanged
    case cardWithWrongUserWalletIdScanned

    var errorDescription: String? {
        rawValue
    }

    var alertBinder: AlertBinder {
        switch self {
        case .duplicateWalletAdded:
            return .init(title: "", message: Localization.userWalletListErrorWalletAlreadySaved)
        case .biometricsChanged:
            return .init(title: Localization.commonAttention, message: Localization.keyInvalidatedWarningDescription)
        case .cardWithWrongUserWalletIdScanned:
            return .init(title: Localization.commonWarning, message: Localization.errorWrongWalletTapped)
        }
    }
}

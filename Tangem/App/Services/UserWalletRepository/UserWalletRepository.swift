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
    var delegate: UserWalletRepositoryDelegate? { get set }
    var models: [CardViewModel] { get }
    var selectedModel: CardViewModel? { get }
    var selectedUserWalletId: Data? { get }
    var isEmpty: Bool { get }
    var isLocked: Bool { get }
    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> { get }

    func unlock(with method: UserWalletRepositoryUnlockMethod, completion: @escaping (UserWalletRepositoryResult?) -> Void)
    func setSelectedUserWalletId(_ userWalletId: Data?, reason: UserWalletRepositorySelectionChangeReason)

    func add(_ completion: @escaping (UserWalletRepositoryResult?) -> Void)
    func contains(_ userWallet: UserWallet) -> Bool
    func save(_ userWallet: UserWallet)
    func delete(_ userWallet: UserWallet)
    func clear()
}

protocol UserWalletRepositoryDelegate: AnyObject {
    func showTOS(at url: URL, _ completion: @escaping (Bool) -> Void)
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
    case success(CardViewModel)
    case onboarding(OnboardingInput)
    case troubleshooting
    case error(Error)
}

enum UserWalletRepositoryEvent {
    case locked(reason: UserWalletRepositoryLockReason)
    case scan(isScanning: Bool)
    case inserted(userWallet: UserWallet)
    case updated(userWalletModel: UserWalletModel)
    case deleted(userWalletId: Data)
    case selected(userWallet: UserWallet, reason: UserWalletRepositorySelectionChangeReason)
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
    case card(userWallet: UserWallet?)
}

enum UserWalletRepositoryError: String, Error, LocalizedError {
    case duplicateWalletAdded

    var errorDescription: String? {
        self.rawValue
    }

    var alertBinder: AlertBinder {
        switch self {
        case .duplicateWalletAdded:
            return .init(title: "", message: "user_wallet_list_error_wallet_already_saved".localized)
        }
    }
}

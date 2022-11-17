//
//  UserWalletRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UserWalletRepository {
    var delegate: UserWalletRepositoryDelegate? { get set }
    var models: [CardViewModel] { get }
    var selectedModel: CardViewModel? { get }
    var selectedUserWalletId: Data? { get set }
    var isEmpty: Bool { get }
    var isUnlocked: Bool { get }
    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> { get }

    func scanPublisher(with batch: String?) ->  AnyPublisher<UserWalletRepositoryResult?, Never>

    func lock()
    func unlock(with method: UserWalletRepositoryUnlockMethod, completion: @escaping (Result<Void, Error>) -> Void)

    func didScan(card: CardDTO)

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

extension UserWalletRepository {
    func scanPublisher(with batch: String? = nil) ->  AnyPublisher<UserWalletRepositoryResult?, Never> {
        scanPublisher(with: batch)
    }
}

protocol ScanListener {
    func onScan(cardInfo: CardInfo)
}

enum UserWalletRepositoryResult {
    case success(CardViewModel)
    case onboarding(OnboardingInput)
    case troubleshooting
    case error(AlertBinder)
}

enum UserWalletRepositoryEvent {
    case locked
}

enum UserWalletRepositoryError: Error {
    case noCard
}

enum UserWalletRepositoryUnlockMethod {
    case biometry
    case card(userWallet: UserWallet?)
}

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

    func scan(with batch: String?, requestBiometrics: Bool, _ completion: @escaping (Result<CardViewModel, Error>) -> Void)
    func scanPublisher(with batch: String?, requestBiometrics: Bool) ->  AnyPublisher<CardViewModel, Error>

    func add(_ cardModels: [CardViewModel])
    func removeModel(with userWalletId: Data)
    func clear()
    func didSwitch(to cardModel: CardViewModel)
}

protocol UserWalletRepositoryDelegate: AnyObject {
    func showTOS(at url: URL, _ completion: @escaping (Bool) -> Void)
}

private struct UserWalletRepositoryKey: InjectionKey {
    static var currentValue: UserWalletRepository = CommonUserWalletRepository()
}

extension InjectedValues {
    var cardsRepository: UserWalletRepository {
        get { Self[UserWalletRepositoryKey.self] }
        set { Self[UserWalletRepositoryKey.self] = newValue }
    }
}

extension UserWalletRepository {
    func scanPublisher(with batch: String? = nil, requestBiometrics: Bool = false) ->  AnyPublisher<CardViewModel, Error> {
        scanPublisher(with: batch, requestBiometrics: requestBiometrics)
    }

    func add(_ cardModel: CardViewModel) {
        add([cardModel])
    }
}

protocol ScanListener {
    func onScan(cardInfo: CardInfo)
}

enum CardsRepositoryError: Error {
    case noCard
}

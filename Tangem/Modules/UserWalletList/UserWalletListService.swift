//
//  UserWalletListService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import enum TangemSdk.TangemSdkError

protocol UserWalletListService: AnyObject, Initializable {
    var models: [CardViewModel] { get }

    var selectedModel: CardViewModel? { get }
    var selectedUserWalletId: Data? { get set }

    var isEmpty: Bool { get }

    var isUnlocked: Bool { get }

    func unlockWithBiometry(completion: @escaping (Result<Void, Error>) -> Void)
    func unlockWithCard(_ userWallet: UserWallet, completion: @escaping (Result<Void, Error>) -> Void)

    func contains(_ userWallet: UserWallet) -> Bool
    func save(_ userWallet: UserWallet) -> Bool
    func delete(_ userWallet: UserWallet)
    func clear()
}

private struct UserWalletListServiceKey: InjectionKey {
    static var currentValue: UserWalletListService = CommonUserWalletListService()
}

extension InjectedValues {
    var userWalletListService: UserWalletListService {
        get { Self[UserWalletListServiceKey.self] }
        set { Self[UserWalletListServiceKey.self] = newValue }
    }
}

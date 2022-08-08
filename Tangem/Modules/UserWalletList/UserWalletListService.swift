//
//  UserWalletListService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol UserWalletListService: AnyObject, Initializable {
    var multiCurrencyModels: [CardViewModel] { get }
    var singleCurrencyModels: [CardViewModel] { get }

    var selectedUserWalletId: Data? { get set }

    func deleteWallet(_ userWallet: UserWallet)
    func saveIfNeeded(_ userWallet: UserWallet) -> Bool
    func setName(_ userWallet: UserWallet, name: String)
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

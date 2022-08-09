//
//  CommonUserWalletListService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class CommonUserWalletListService: UserWalletListService {
    var multiCurrencyModels: [CardViewModel] = []
    var singleCurrencyModels: [CardViewModel] = []

    var allModels: [CardViewModel] {
        multiCurrencyModels + singleCurrencyModels
    }

    var selectedModel: CardViewModel? {
        return allModels.first {
            $0.userWallet.userWalletId == selectedUserWalletId
        }
    }

    var selectedUserWalletId: Data? {
        get {
            let id = AppSettings.shared.selectedUserWalletId
            return id.isEmpty ? nil : id
        }
        set {
            AppSettings.shared.selectedUserWalletId = newValue ?? Data()
        }
    }

    init() {
        let userWallets = savedUserWallets()
        let cardViewModels = userWallets.map {
            CardViewModel(userWallet: $0)
        }

        multiCurrencyModels = cardViewModels.filter { $0.userWallet.isMultiCurrency }
        singleCurrencyModels = cardViewModels.filter { !$0.userWallet.isMultiCurrency }
    }

    func initialize() {

    }

    func deleteWallet(_ userWallet: UserWallet) {
        let userWalletId = userWallet.userWalletId
        var userWallets = savedUserWallets()
        userWallets.removeAll {
            $0.userWalletId == userWalletId
        }
        multiCurrencyModels.removeAll { $0.userWallet.userWalletId == userWalletId }
        singleCurrencyModels.removeAll { $0.userWallet.userWalletId == userWalletId }
        saveUserWallets(userWallets)
    }

    func contains(_ userWallet: UserWallet) -> Bool {
        let userWallets = savedUserWallets()
        return userWallets.contains { $0.userWalletId == userWallet.userWalletId }
    }

    func save(_ userWallet: UserWallet) -> Bool {
        var userWallets = savedUserWallets()
        }

        userWallets.append(userWallet)
        saveUserWallets(userWallets)

        if userWallet.isMultiCurrency {
            multiCurrencyModels.append(.init(userWallet: userWallet))
        } else {
            singleCurrencyModels.append(.init(userWallet: userWallet))
        }

        return true
    }

    func setName(_ userWallet: UserWallet, name: String) {
        var userWallets = savedUserWallets()

        for i in 0 ..< userWallets.count {
            if userWallets[i].userWalletId == userWallet.userWalletId {
                userWallets[i].name = name
            }
        }

        allModels.forEach {
            if $0.userWallet.userWalletId == userWallet.userWalletId {
                $0.cardInfo.name = name
            }
        }

        saveUserWallets(userWallets)
    }

    private func savedUserWallets() -> [UserWallet] {
        do {
            let data = AppSettings.shared.userWallets
            return try JSONDecoder().decode([UserWallet].self, from: data)
        } catch {
            print(error)
            return []
        }
    }

    private func saveUserWallets(_ userWallets: [UserWallet]) {
        do {
            let data = try JSONEncoder().encode(userWallets)
            AppSettings.shared.userWallets = data
        } catch {
            print(error)
        }
    }
}

fileprivate extension UserWallet {
    var isMultiCurrency: Bool {
        if case .note = self.walletData {
            return false
        } else {
            return true
        }
    }
}

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

    var selectedUserWalletId: Data {
        get {
            AppSettings.shared.selectedUserWalletId
        }
        set {
            AppSettings.shared.selectedUserWalletId = newValue
        }
    }

    init() {
        let userWallets = savedUserWallets()
        let cardViewModels = userWallets.map {
            CardViewModel(userWallet: $0)
        }

        singleCurrencyModels = cardViewModels.filter {
            if case .note = $0.userWallet.walletData {
                return true
            } else {
                return false
            }
        }

        multiCurrencyModels = cardViewModels.filter {
            if case .note = $0.userWallet.walletData {
                return false
            } else {
                return true
            }
        }
    }

    func initialize() {

    }

    func deleteWallet(_ userWallet: UserWallet) {
        var userWallets = savedUserWallets()
        userWallets.removeAll {
            $0.userWalletId == userWallet.userWalletId
        }
        saveUserWallets(userWallets)
    }

    func saveIfNeeded(_ userWallet: UserWallet) -> Bool {
        var userWallets = savedUserWallets()
        guard !userWallets.contains(where: { $0.userWalletId == userWallet.userWalletId }) else {
            return false
        }

        userWallets.append(userWallet)
        saveUserWallets(userWallets)

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

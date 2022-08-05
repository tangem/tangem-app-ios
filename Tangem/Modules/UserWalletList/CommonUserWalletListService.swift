//
//  CommonUserWalletListService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class CommonUserWalletListService {
    var multiCurrencyUserWallets: [UserWallet] = []
    var singleCurrencyUserWallets: [UserWallet] = []

    var allUserWallets: [UserWallet] {
        multiCurrencyUserWallets + singleCurrencyUserWallets
    }

    var selectedUserWallet: UserWallet? {
        allUserWallets.first(where: { $0.userWalletId == selectedUserWalletId }) ?? allUserWallets.first
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

        singleCurrencyUserWallets = userWallets.filter {
            if case .note = $0.walletData {
                return true
            } else {
                return false
            }
        }
        multiCurrencyUserWallets = userWallets.filter {
            if case .note = $0.walletData {
                return false
            } else {
                return true
            }
        }
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

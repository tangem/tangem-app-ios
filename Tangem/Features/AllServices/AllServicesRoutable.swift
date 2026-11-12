//
//  AllServicesRoutable.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol AllServicesRoutable: AnyObject {
    func openAddWallet()
    func openShop()
    func openCryptoAccountForm()
    func openJointAccountCreation()
    func openReferral(wallets: [UserWalletModel])
    func closeAllServices()
}

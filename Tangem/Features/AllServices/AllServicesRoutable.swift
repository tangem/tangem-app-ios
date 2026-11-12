//
//  AllServicesRoutable.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol AllServicesRoutable: AnyObject {
    func openAddWallet()
    func openOnboardingModal(with input: OnboardingInput)
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func openScanCardManual()
    func openShop()
    func openCryptoAccountForm()
    func openJointAccountCreation()
    func openReferral(wallets: [UserWalletModel])
    func closeAllServices()
}

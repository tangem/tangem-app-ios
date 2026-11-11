//
//  AddWalletFlowDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
protocol AddWalletFlowDelegate: AnyObject {
    func present(sheet: AddWalletSheetViewModel)
    func dismissSheet()
    func didRequestHardwareWallet()
    func didRequestOnboarding(options: OnboardingCoordinator.Options)
    func didRequestSocialWallet(viewModel: MobileSocialWalletViewModel)
    func didCloseSocialWallet()
    func didAdd(userWalletModel: UserWalletModel)
    func didFinish()
}

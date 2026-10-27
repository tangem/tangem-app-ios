//
//  MobileSocialLoginOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
protocol MobileSocialLoginOutput: AnyObject {
    func socialLoginWillPresentSignIn()
    func socialLoginLoading(_ isLoading: Bool)
    func socialLoginProcessing(_ isProcessing: Bool)
    func socialLoginCompleted(input: MobileSocialWalletInput)
    func socialLoginFailed(failure: MobileSocialWalletFailure)
}

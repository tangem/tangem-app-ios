//
//  OnboardingStepsBuilderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol OnboardingStepsBuilderFactory {
    func makeOnboardingStepsBuilder(backupService: BackupService) -> OnboardingStepsBuilder
}

// MARK: - Wallets

protocol WalletOnboardingStepsBuilderFactory: OnboardingStepsBuilderFactory, CardContainer {}

extension UserWalletConfig where Self: WalletOnboardingStepsBuilderFactory {
    func makeOnboardingStepsBuilder(backupService: BackupService) -> OnboardingStepsBuilder {
        return WalletOnboardingStepsBuilder(
            card: card,
            touId: tou.id,
            backupService: backupService
        )
    }
}

// MARK: - Single cards

protocol SingleCardOnboardingStepsBuilderFactory: OnboardingStepsBuilderFactory, CardContainer {}

extension UserWalletConfig where Self: SingleCardOnboardingStepsBuilderFactory {
    func makeOnboardingStepsBuilder(backupService: BackupService) -> OnboardingStepsBuilder {
        return SingleCardOnboardingStepsBuilder(
            card: card,
            touId: tou.id
        )
    }
}

// MARK: - Note cards

protocol NoteCardOnboardingStepsBuilderFactory: OnboardingStepsBuilderFactory, CardContainer {}

extension UserWalletConfig where Self: NoteCardOnboardingStepsBuilderFactory {
    func makeOnboardingStepsBuilder(backupService: BackupService) -> OnboardingStepsBuilder {
        return NoteOnboardingStepsBuilder(
            card: card,
            touId: tou.id
        )
    }
}

//
//  OnboardingInputFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class OnboardingInputFactory {
    private let cardInput: OnboardingInput.CardInput
    private let twinData: TwinData?
    private let primaryCard: PrimaryCard?
    private let backupServiceFactory: BackupServiceFactory
    private let onboardingStepsBuilderFactory: OnboardingStepsBuilderFactory

    init(
        cardInput: OnboardingInput.CardInput,
        twinData: TwinData?,
        primaryCard: PrimaryCard?,
        backupServiceFactory: BackupServiceFactory,
        onboardingStepsBuilderFactory: OnboardingStepsBuilderFactory
    ) {
        self.cardInput = cardInput
        self.twinData = twinData
        self.primaryCard = primaryCard
        self.backupServiceFactory = backupServiceFactory
        self.onboardingStepsBuilderFactory = onboardingStepsBuilderFactory
    }

    func makeOnboardingInput() -> OnboardingInput? {
        let backupService = backupServiceFactory.makeBackupService()

        if let primaryCard {
            backupService.setPrimaryCard(primaryCard)
        }

        let stepsBuilder = onboardingStepsBuilderFactory.makeOnboardingStepsBuilder(backupService: backupService)
        let steps = stepsBuilder.buildOnboardingSteps()

        if steps.needOnboarding {
            return .init(
                backupService: backupService,
                steps: steps,
                cardInput: cardInput,
                twinData: twinData
            )
        }

        return nil
    }

    func makeBackupInput() -> OnboardingInput? {
        let backupService = backupServiceFactory.makeBackupService()

        if let primaryCard {
            backupService.setPrimaryCard(primaryCard)
        }

        let stepsBuilder = onboardingStepsBuilderFactory.makeOnboardingStepsBuilder(backupService: backupService)
        guard let steps = stepsBuilder.buildBackupSteps() else {
            return nil
        }

        return .init(
            backupService: backupService,
            steps: steps,
            cardInput: cardInput,
            twinData: nil,
            isStandalone: true
        )
    }
}

class TwinInputFactory {
    private let cardInput: OnboardingInput.CardInput
    private let twinData: TwinData
    private let backupServiceFactory: BackupServiceFactory

    init(
        cardInput: OnboardingInput.CardInput,
        twinData: TwinData,
        backupServiceFactory: BackupServiceFactory
    ) {
        self.cardInput = cardInput
        self.twinData = twinData
        self.backupServiceFactory = backupServiceFactory
    }

    func makeTwinInput() -> OnboardingInput {
        return .init(
            backupService: backupServiceFactory.makeBackupService(),
            steps: .twins(TwinsOnboardingStep.twinningSteps),
            cardInput: cardInput,
            twinData: nil,
            isStandalone: true
        )
    }
}

class ResumeBackupInputFactory {
    private let cardId: String
    private let backupServiceFactory: BackupServiceFactory

    init(cardId: String, backupServiceFactory: BackupServiceFactory) {
        self.cardId = cardId
        self.backupServiceFactory = backupServiceFactory
    }

    func makeBackupInput() -> OnboardingInput {
        return .init(
            backupService: backupServiceFactory.makeBackupService(),
            steps: .wallet(WalletOnboardingStep.resumeBackupSteps),
            cardInput: .cardId(cardId),
            twinData: nil,
            isStandalone: true
        )
    }
}

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
    private let cardInfo: CardInfo
    private let cardModel: CardViewModel?
    private let sdkFactory: TangemSdkFactory & BackupServiceFactory
    private let onboardingStepsBuilderFactory: OnboardingStepsBuilderFactory

    init(
        cardInfo: CardInfo,
        cardModel: CardViewModel?,
        sdkFactory: TangemSdkFactory & BackupServiceFactory,
        onboardingStepsBuilderFactory: OnboardingStepsBuilderFactory
    ) {
        self.cardInfo = cardInfo
        self.cardModel = cardModel
        self.sdkFactory = sdkFactory
        self.onboardingStepsBuilderFactory = onboardingStepsBuilderFactory
    }

    func makeOnboardingInput() -> OnboardingInput? {
        let backupService = sdkFactory.makeBackupService()

        if let primaryCard = cardInfo.primaryCard {
            backupService.setPrimaryCard(primaryCard)
        }

        let stepsBuilder = onboardingStepsBuilderFactory.makeOnboardingStepsBuilder(backupService: backupService)
        let steps = stepsBuilder.buildOnboardingSteps()

        guard steps.needOnboarding else {
            return nil
        }

        let tangemSdk = sdkFactory.makeTangemSdk()
        let cardInteractor = CardInteractor(tangemSdk: tangemSdk, cardInfo: cardInfo)

        let cardModel = tryGetCardViewModel()
        let cardInput: OnboardingInput.CardInput = cardModel.map { .cardModel($0) } ?? .cardInfo(cardInfo)

        return .init(
            backupService: backupService,
            cardInteractor: cardInteractor,
            steps: steps,
            cardInput: cardInput,
            twinData: cardInfo.walletData.twinData,
            stepsBuilder: stepsBuilder // for saltpay
        )
    }

    func makeBackupInput() -> OnboardingInput? {
        guard let cardModel else { return nil }

        let backupService = sdkFactory.makeBackupService()

        if let primaryCard = cardInfo.primaryCard {
            backupService.setPrimaryCard(primaryCard)
        }

        let stepsBuilder = onboardingStepsBuilderFactory.makeOnboardingStepsBuilder(backupService: backupService)
        guard let steps = stepsBuilder.buildBackupSteps() else {
            return nil
        }

        return .init(
            backupService: backupService,
            cardInteractor: nil,
            steps: steps,
            cardInput: .cardModel(cardModel),
            twinData: nil,
            isStandalone: true
        )
    }

    private func tryGetCardViewModel() -> CardViewModel? {
        if let cardModel {
            return cardModel
        }

        if !cardInfo.card.wallets.isEmpty {
            let config = UserWalletConfigFactory(cardInfo).makeConfig()
            let userWallet = CardViewModel(cardInfo: cardInfo, config: config)
            userWallet.userWalletModel?.initialUpdate()
            return userWallet
        }

        return nil
    }
}

class TwinInputFactory {
    private let cardInput: OnboardingInput.CardInput
    private let userWalletToDelete: UserWallet? // Delete on retwin
    private let twinData: TwinData
    private let sdkFactory: TangemSdkFactory & BackupServiceFactory

    init(
        cardInput: OnboardingInput.CardInput,
        userWalletToDelete: UserWallet?,
        twinData: TwinData,
        sdkFactory: TangemSdkFactory & BackupServiceFactory
    ) {
        self.cardInput = cardInput
        self.userWalletToDelete = userWalletToDelete
        self.twinData = twinData
        self.sdkFactory = sdkFactory
    }

    func makeTwinInput() -> OnboardingInput {
        return .init(
            backupService: sdkFactory.makeBackupService(),
            cardInteractor: nil,
            steps: .twins(TwinsOnboardingStep.twinningSteps),
            cardInput: cardInput,
            twinData: twinData,
            isStandalone: true,
            userWalletToDelete: userWalletToDelete
        )
    }
}

class ResumeBackupInputFactory {
    private let cardId: String
    private let tangemSdkFactory: TangemSdkFactory
    private let backupServiceFactory: BackupServiceFactory

    init(cardId: String, tangemSdkFactory: TangemSdkFactory, backupServiceFactory: BackupServiceFactory) {
        self.cardId = cardId
        self.tangemSdkFactory = tangemSdkFactory
        self.backupServiceFactory = backupServiceFactory
    }

    func makeBackupInput() -> OnboardingInput {
        return .init(
            backupService: backupServiceFactory.makeBackupService(),
            cardInteractor: nil,
            steps: .wallet(WalletOnboardingStep.resumeBackupSteps),
            cardInput: .cardId(cardId),
            twinData: nil,
            isStandalone: true
        )
    }
}

//
//  OnboardingStepsSetupService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine
import BlockchainSdk

class CommonOnboardingStepsSetupService: OnboardingStepsSetupService {
    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding

    static var previewSteps: [SingleCardOnboardingStep] {
        [.createWallet, .topup, .successTopup]
    }

    func steps(for cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error> {
        let card = cardInfo.card

        if cardInfo.isTangemWallet {
            return stepsForWallet(cardInfo)
        } else if cardInfo.isTangemNote {
            return stepsForNote(cardInfo)
        } else if card.isTwinCard {
            return stepsForTwins(cardInfo)
        }

        var steps: [SingleCardOnboardingStep] = []

        if card.wallets.isEmpty {
            steps.append(.createWallet)
            steps.append(.success)
        }

        return steps.isEmpty ? .justWithError(output: .singleWallet([])) : .justWithError(output: .singleWallet(steps))
    }

    func twinRecreationSteps(for cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error> {
        var steps: [TwinsOnboardingStep] = []
        steps.append(.alert)
        steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
        steps.append(.success)
        return .justWithError(output: .twins(steps))
    }

    func stepsForBackupResume() -> AnyPublisher<OnboardingSteps, Error> {
        return .justWithError(output: .wallet([.backupCards, .success]))
    }

    func backupSteps(_ cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error> {
        return .justWithError(output: .wallet(makeBackupSteps(cardInfo)))
    }

    private func stepsForNote(_ cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error> {
        let walletModel = WalletManagerAssembly.makeAllWalletModels(from: cardInfo)
        var steps: [SingleCardOnboardingStep] = []
        guard walletModel.count == 1 else {
            steps.append(.createWallet)
            steps.append(.topup)
            steps.append(.successTopup)
            return .justWithError(output: .singleWallet(steps))
        }

        if !AppSettings.shared.cardsStartedActivation.contains(cardInfo.card.cardId) {
            return .justWithError(output: .singleWallet(steps))
        }

        steps.append(.topup)
        steps.append(.successTopup)
        return .justWithError(output: .singleWallet(steps))
    }

    private func stepsForTwins(_ cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error> {
        guard let twinCardInfo = cardInfo.twinCardInfo else {
            return .anyFail(error: "Twin card doesn't contain essential data (Twin card info)")
        }

        var steps = [TwinsOnboardingStep]()

        if !AppSettings.shared.isTwinCardOnboardingWasDisplayed { // show intro only once
            AppSettings.shared.isTwinCardOnboardingWasDisplayed = true
            let twinPairCid = AppTwinCardIdFormatter.format(cid: "", cardNumber: twinCardInfo.series.pair.number)
            steps.append(.intro(pairNumber: "\(twinPairCid)"))
        }

        if cardInfo.card.wallets.isEmpty { // twin without created wallet. Start onboarding
            steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
            steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
            return .justWithError(output: .twins(steps))
        } else { // twin with created wallet
            if twinCardInfo.pairPublicKey == nil { // is not twinned
                steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
                steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                return .justWithError(output: .twins(steps))
            } else { // is twinned
                if AppSettings.shared.cardsStartedActivation.contains(cardInfo.card.cardId) { // card is in onboarding process, go to topup
                    steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                    return .justWithError(output: .twins(steps))
                } else { // unknown twin, ready to use, go to main
                    return .justWithError(output: .twins(steps))
                }
            }
        }
    }

    private func stepsForWallet(_ cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error> {
        if let backupStatus = cardInfo.card.backupStatus,
           backupStatus.isActive ||
           (cardInfo.card.wallets.count != 0 &&
               !AppSettings.shared.cardsStartedActivation.contains(cardInfo.card.cardId)) {
            return .justWithError(output: .wallet([]))
        }

        let steps = makeBackupSteps(cardInfo)
        return .justWithError(output: .wallet(steps))
    }

    private func makeBackupSteps(_ cardInfo: CardInfo) -> [WalletOnboardingStep] {
        if !cardInfo.card.settings.isBackupAllowed {
            return []
        }

        var steps: [WalletOnboardingStep] = .init()

        // todo: respect involved cards?

        if cardInfo.card.wallets.isEmpty {
            steps.append(.createWallet)
            steps.append(.backupIntro)
        } else {
            steps.append(.backupIntro)

            if !backupServiceProvider.backupService.primaryCardIsSet {
                steps.append(.scanPrimaryCard)
            }
        }

        if backupServiceProvider.backupService.addedBackupCardsCount < BackupService.maxBackupCardsCount {
            steps.append(.selectBackupCards)
        }

        steps.append(.backupCards)
        steps.append(.success)

        return steps
    }
}

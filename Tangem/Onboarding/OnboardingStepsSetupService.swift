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

class OnboardingStepsSetupService {
    
    weak var userPrefs: UserPrefsService!
    weak var assembly: Assembly!
    weak var backupService: BackupService!
    
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
        let walletModel = assembly.makeAllWalletModels(from: cardInfo)
        var steps: [SingleCardOnboardingStep] = []
        guard walletModel.count == 1 else {
            steps.append(.createWallet)
            steps.append(.topup)
            steps.append(.successTopup)
            return .justWithError(output: .singleWallet(steps))
        }
        
        if !self.userPrefs.cardsStartedActivation.contains(cardInfo.card.cardId) {
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
        
        if !userPrefs.isTwinCardOnboardingWasDisplayed { //show intro only once
            userPrefs.isTwinCardOnboardingWasDisplayed = true
            let twinPairCid = AppTwinCardIdFormatter.format(cid:"", cardNumber: twinCardInfo.series.pair.number)
            steps.append(.intro(pairNumber: "\(twinPairCid)"))
        }
        
        if cardInfo.card.wallets.isEmpty { //twin without created wallet. Start onboarding
            steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
            steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
            return .justWithError(output: .twins(steps))
        } else {//twin with created wallet
            if twinCardInfo.pairPublicKey == nil { //is not twinned
                //check balance because of legacy bug
              if let walletModel = assembly.makeAllWalletModels(from: cardInfo).first {
                  return Future { promise in
                      walletModel.walletManager.update { result in
                          switch result {
                          case .success:
                              if walletModel.isEmptyIncludingPendingIncomingTxs { //Empty balance, It's safe to onboarding
                                  steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
                                  steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                                  return promise(.success(.twins(steps)))
                              } else { //bugged case, has balance go to main
                                  return promise(.success(.twins([])))
                              }
                          case .failure(let error):
                              promise(.failure(error))
                          }
                      }
                  }
                  .eraseToAnyPublisher()
              } else { //will use this branch in future releases. Just start onboarding
                  steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
                  steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                  return .justWithError(output: .twins(steps))
              }
            } else { //is twinned
                if userPrefs.cardsStartedActivation.contains(cardInfo.card.cardId) { //card is in onboarding process, go to topup
                    steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                    return .justWithError(output: .twins(steps))
                } else { //unknown twin, ready to use, go to main
                    return .justWithError(output: .twins(steps))
                }
            }
        }
    }
    
    private func stepsForWallet(_ cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error> {
        if let backupStatus = cardInfo.card.backupStatus,
           backupStatus.isActive ||
            (cardInfo.card.wallets.count != 0 &&
                !userPrefs.cardsStartedActivation.contains(cardInfo.card.cardId)) {
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
        
        //todo: respect involved cards?
        
        if cardInfo.card.wallets.isEmpty {
            steps.append(.createWallet)
            steps.append(.backupIntro)
        } else {
            steps.append(.backupIntro)
            
            if !backupService.primaryCardIsSet {
                steps.append(.scanPrimaryCard)
            }
        }
        
        if backupService.addedBackupCardsCount < BackupService.maxBackupCardsCount {
            steps.append(.selectBackupCards)
        }
        
        steps.append(.backupCards)
        steps.append(.success)
        
       return steps
    }
}

//
//  OnboardingStepsSetupService.swift
//  Tangem Tap
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
    
    static var previewSteps: [SingleCardOnboardingStep] {
        [.createWallet, .topup, .successTopup]
    }
    
    func stepsWithCardImage(for cardModel: CardViewModel) -> AnyPublisher<(OnboardingSteps, UIImage), Error> {
        Publishers.Zip(
            steps(for: cardModel.cardInfo),
            cardModel.imageLoaderPublisher
        )
        .eraseToAnyPublisher()
    }
    
    func steps(for cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error> {
        let card = cardInfo.card
        
        if card.isTangemWallet {
            return stepsForWallet(cardInfo)
        } else if cardInfo.isTangemNote {
            return stepsForNote(cardInfo)
        } else if card.isTwinCard {
            return stepsForTwins(cardInfo)
        }
        
        var steps: [SingleCardOnboardingStep] = []
        
        if card.wallets.count == 0 {
            steps.append(.createWallet)
            steps.append(.success)
        }
        
        return steps.count > 0 ? .justWithError(output: .singleWallet(steps)) : .justWithError(output: .singleWallet([]))
    }
    
    func twinRecreationSteps(for cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error> {
        var steps: [TwinsOnboardingStep] = []
        steps.append(.alert)
        steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
        steps.append(.success)
        return .justWithError(output: .twins(steps))
    }
    
    private func stepsForNote(_ cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error> {
        let walletModel = assembly.loadWallets(from: cardInfo)
        var steps: [SingleCardOnboardingStep] = []
        guard walletModel.count == 1 else {
            steps.append(.createWallet)
            steps.append(.topup)
            steps.append(.successTopup)
            return .justWithError(output: .singleWallet(steps))
        }
        
        let model = walletModel.first!
        return Future { promise in
            model.walletManager.update { [unowned self] result in
                switch result {
                case .success:
                    if model.isEmptyIncludingPendingIncomingTxs {
                        steps.append(.topup)
                    } else if !self.userPrefs.cardsStartedActivation.contains(cardInfo.card.cardId) {
                        return promise(.success(.singleWallet([])))
                    }
                    steps.append(.successTopup)
                    promise(.success(.singleWallet(steps)))
                case .failure(let error):
                    if case WalletError.noAccount = error {
                        steps.append(.topup)
                        steps.append(.successTopup)
                        promise(.success(.singleWallet(steps)))
                        return
                    }
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private func stepsForTwins(_ cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error> {
        guard let twinCardInfo = cardInfo.twinCardInfo else {
            return .anyFail(error: "Twin card doesn't contain essential data (Twin card info)")
        }
        
        var steps = [TwinsOnboardingStep]()
        
        if !userPrefs.cardsStartedActivation.contains(cardInfo.card.cardId) {
            if twinCardInfo.pairPublicKey != nil && cardInfo.card.wallets.first != nil {
                return .justWithError(output: .twins([]))
            } else {
            let twinPairCid = TapTwinCardIdFormatter.format(cid:"", cardNumber: twinCardInfo.series.pair.number)
            steps.append(.intro(pairNumber: "\(twinPairCid)"))
            
            if twinCardInfo.pairPublicKey != nil && cardInfo.card.wallets.first != nil {
                return .justWithError(output: .twins(steps))
            }
        }
        
        let walletModel = assembly.loadWallets(from: cardInfo)
        
        if (walletModel.count == 0 && cardInfo.twinCardInfo?.pairPublicKey == nil) {
            steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
            steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
            return .justWithError(output: .twins(steps))
        } else {
            let model = walletModel.first!
            return Future { promise in
                model.walletManager.update { [unowned self] result in
                    switch result {
                    case .success:
                        if !model.isEmptyIncludingPendingIncomingTxs
                            && cardInfo.twinCardInfo?.pairPublicKey == nil { //bugged case, has balance go to main
                            return promise(.success(.twins([])))
                        }
                        
                        if model.isEmptyIncludingPendingIncomingTxs {
                            if cardInfo.twinCardInfo?.pairPublicKey == nil { //It's safe to twin
                                steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
                                steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                                return promise(.success(.twins(steps)))
                            }
                            
                            steps.append(.topup)
                        } else if !self.userPrefs.cardsStartedActivation.contains(cardInfo.card.cardId) {
                            return promise(.success(.twins([])))
                        }
                        steps.append(.confetti)
                        steps.append(.done)
                        promise(.success(.twins(steps)))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
            .eraseToAnyPublisher()
        }
    }
    
    private func stepsForWallet(_ cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error> {
        if let backupStatus = cardInfo.card.backupStatus, backupStatus.isActive {
            return .justWithError(output: .wallet([]))
        }
        
        var steps = [WalletOnboardingStep]()
        if cardInfo.card.wallets.count == 0 {
            steps.append(.createWallet)
            steps.append(.backupIntro)
        } else if userPrefs.cardsStartedActivation.contains(cardInfo.card.cardId) {
            steps.append(.backupIntro)
            steps.append(.scanOriginCard)
        } else {
            return .justWithError(output: .wallet([]))
        }
        
        steps.append(contentsOf: [.selectBackupCards, .backupCards, .success])
        return .justWithError(output: .wallet(steps))
    }
    
}

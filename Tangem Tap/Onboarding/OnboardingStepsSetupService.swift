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

enum OnboardingSteps {
    case singleWallet([NoteOnboardingStep]), twins([TwinsOnboardingStep]), wallet
    
    var needOnboarding: Bool {
        switch self {
        case .singleWallet(let steps):
            return steps.count > 0
        case .twins(let steps):
            return steps.count > 0
        case .wallet:
             return false
        }
    }
}

class OnboardingStepsSetupService {
    
    weak var userPrefs: UserPrefsService!
    weak var assembly: Assembly!
    
    static var previewSteps: [NoteOnboardingStep] {
        [.read, .createWallet, .topup, .confetti, .goToMain]
    }
    
    func steps(for cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error> {
        let card = cardInfo.card
        
        if card.isTangemWallet {
            return stepsForWallet(cardInfo)
        } else if card.isTangemNote {
            return stepsForNote(card)
        } else if card.isTwinCard {
            return stepsForTwins(cardInfo)
        }
        
        var steps: [NoteOnboardingStep] = [.read]
        
        if card.wallets.count == 0 {
            steps.append(.createWallet)
        }
        
        return steps.count > 1 ? .justWithError(output: .singleWallet(steps)) : .justWithError(output: .singleWallet([]))
    }
    
    private func stepsForNote(_ card: Card) -> AnyPublisher<OnboardingSteps, Error> {
        let walletModel = assembly.loadWallets(from: CardInfo(card: card))
        var steps: [NoteOnboardingStep] = [.read]
        guard walletModel.count == 1 else {
            steps.append(.createWallet)
            steps.append(.topup)
            steps.append(.confetti)
            steps.append(.goToMain)
            return .justWithError(output: .singleWallet(steps))
        }
        
        let model = walletModel.first!
        return Future { promise in
            model.walletManager.update { [unowned self] result in
                switch result {
                case .success:
                    if model.isEmptyIncludingPendingIncomingTxs {
                        steps.append(.topup)
                    } else if !self.userPrefs.cardsStartedActivation.contains(card.cardId) {
                        return promise(.success(.singleWallet([])))
                    }
                    steps.append(.confetti)
                    steps.append(.goToMain)
                    promise(.success(.singleWallet(steps)))
                case .failure(let error):
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
        
        steps.append(.intro(pairNumber: TapTwinCardIdFormatter.format(cid: twinCardInfo.pairCid, cardNumber: twinCardInfo.series.pair.number)))
        let walletModel = assembly.loadWallets(from: cardInfo)
        if (walletModel.count == 0 || cardInfo.twinCardInfo?.pairPublicKey == nil) {
            steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
            steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
            return .justWithError(output: .twins(steps))
        } else {
            let model = walletModel.first!
            return Future { promise in
                model.walletManager.update { [unowned self] result in
                    switch result {
                    case .success:
                        if model.isEmptyIncludingPendingIncomingTxs {
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
        .justWithError(output: .wallet)
    }
    
}

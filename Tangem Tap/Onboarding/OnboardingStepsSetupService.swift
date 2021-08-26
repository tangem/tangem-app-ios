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

class OnboardingStepsSetupService {
    
    weak var userPrefs: UserPrefsService!
    weak var assembly: Assembly!
    
    static var previewSteps: [OnboardingStep] {
        [.read, .createWallet, .topup, .confetti, .goToMain]
    }
    
    func steps(for cardInfo: CardInfo) -> AnyPublisher<[OnboardingStep], Error> {
        let card = cardInfo.card
        var steps: [OnboardingStep] = [.read]
        
        if card.wallets.count == 0 {
            steps.append(.createWallet)
        }
        
        if card.isTangemWallet {
            return stepsForWallet(cardInfo, selectedSteps: steps)
        } else if card.isTangemNote {
            return stepsForNote(card, selectedSteps: steps)
        } else if card.isTwinCard {
            return stepsForTwins(cardInfo, selectedSteps: steps)
        }
        
        return steps.count > 1 ? .justWithError(output: steps) : .justWithError(output: [])
    }
    
    private func stepsForNote(_ card: Card, selectedSteps: [OnboardingStep]) -> AnyPublisher<[OnboardingStep], Error> {
        let walletModel = assembly.loadWallets(from: CardInfo(card: card))
        var steps = selectedSteps
        guard walletModel.count == 1 else {
            steps.append(.topup)
            steps.append(.confetti)
            steps.append(.goToMain)
            return .justWithError(output: steps)
        }
        
        let model = walletModel.first!
        return Future { promise in
            model.walletManager.update { [unowned self] result in
                switch result {
                case .success:
                    if model.wallet.isEmpty {
                        steps.append(.topup)
                    } else if !self.userPrefs.noteCardsStartedActivation.contains(card.cardId) {
                        return promise(.success([]))
                    }
                    steps.append(.confetti)
                    steps.append(.goToMain)
                    promise(.success(steps))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private func stepsForTwins(_ cardInfo: CardInfo, selectedSteps: [OnboardingStep]) -> AnyPublisher<[OnboardingStep], Error> {
        .justWithError(output: selectedSteps)
    }
    
    private func stepsForWallet(_ cardInfo: CardInfo, selectedSteps: [OnboardingStep]) -> AnyPublisher<[OnboardingStep], Error> {
        .justWithError(output: selectedSteps)
    }
    
}

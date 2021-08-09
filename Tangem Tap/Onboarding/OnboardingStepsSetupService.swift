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
    
    func steps(for card: Card) -> AnyPublisher<[OnboardingStep], Error> {
        var steps: [OnboardingStep] = [.read]
        
        if !userPrefs.isTermsOfServiceAccepted {
            steps.append(.disclaimer)
        }
        
        if card.wallets.count == 0 {
            steps.append(.createWallet)
        }
        
        if card.isTangemWallet {
            steps.append(.backup)
        } else if card.isTangemNote {
            return stepsForNote(card, selectedSteps: steps)
        }
        
        if steps.count > 1 {
            steps.append(.confetti)
        }
        steps.append(.goToMain)
        
        return .justWithError(output: steps)
    }
    
    func stepsForNote(_ card: Card, selectedSteps: [OnboardingStep]) -> AnyPublisher<[OnboardingStep], Error> {
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
                    } else {
                        if !self.userPrefs.noteCardsStartedActivation.contains(card.cardId) {
                            steps.append(.goToMain)
                            promise(.success(steps))
                            return
                        }
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
    
}

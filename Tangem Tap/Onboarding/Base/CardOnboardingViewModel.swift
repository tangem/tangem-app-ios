//
//  CardOnboardingViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

class CardOnboardingViewModel: ViewModel {
    
    enum Content {
        case notScanned, note, twin, wallet, other
        
        static func content(for cardModel: CardViewModel) -> Content {
            let card = cardModel.cardInfo.card
            if card.isTwinCard {
                return .twin
            }
            if card.isTangemNote {
                return .note
            }
            if card.isTangemWallet {
                return .wallet
            }
            return .other
        }
        
        static func content(for steps: OnboardingSteps) -> Content {
            switch steps {
            case .note, .older: return .note
            case .twins: return .twin
            case .wallet: return .wallet
            }
        }
        
        var navbarTitle: LocalizedStringKey {
            switch self {
            case .notScanned: return ""
            case .note: return "Activating card"
            case .twin: return "Tangem Twin"
            case .wallet: return "Tangem Wallet"
            case .other: return "Tangem Card"
            }
        }
    }
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var userPrefsService: UserPrefsService!
    
    let isFromMainScreen: Bool
    
    var input: CardOnboardingInput?
    
    var isTermsOfServiceAccepted: Bool { userPrefsService.isTermsOfServiceAccepted }
    
    @Published var content: Content
    @Published var toMain: Bool = false
    
    init() {
        self.isFromMainScreen = false
        self.content = .notScanned
    }
    
    init(cardModel: CardViewModel) {
        isFromMainScreen = true
        content = .content(for: cardModel)
    }
    
    init(input: CardOnboardingInput) {
        isFromMainScreen = true
        content = .content(for: input.steps)
        self.input = input
    }
    
    func reset() {
        guard isFromMainScreen else {
            return
        }
        
        content = .notScanned
    }
    
}

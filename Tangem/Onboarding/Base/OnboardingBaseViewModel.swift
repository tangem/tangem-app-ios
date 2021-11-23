//
//  OnboardingBaseViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

class OnboardingBaseViewModel: ViewModel, ObservableObject {
    
    enum Content {
        case notScanned, singleCard, twin, wallet
        
        static func content(for cardModel: CardViewModel) -> Content {
            let card = cardModel.cardInfo.card
            if card.isTwinCard {
                return .twin
            }
            if cardModel.cardInfo.isTangemWallet {
                return .wallet
            }
            
            return .singleCard
        }
        
        static func content(for steps: OnboardingSteps) -> Content {
            switch steps {
            case .singleWallet: return .singleCard
            case .twins: return .twin
            case .wallet: return .wallet
            }
        }
        
        var navbarTitle: LocalizedStringKey {
            switch self {
            case .notScanned: return ""
            case .singleCard: return "onboarding_navbar_activating_card"
            case .twin: return "Tangem Twin"
            case .wallet: return "Tangem Wallet"
            }
        }
    }
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var userPrefsService: UserPrefsService!
    
    let isFromMainScreen: Bool
    
    var isTermsOfServiceAccepted: Bool { userPrefsService.isTermsOfServiceAccepted }
    
    @Published var content: Content
   // [REDACTED_USERNAME] var toMain: Bool = false
    
    private var resetSubscription: AnyCancellable?
    
    init() {
        self.isFromMainScreen = false
        self.content = .notScanned
    }
    
    init(cardModel: CardViewModel) {
        isFromMainScreen = true
        content = .content(for: cardModel)
    }
    
    init(input: OnboardingInput) {
        isFromMainScreen = true
        content = .content(for: input.steps)
    }
    
    func bind() {
        resetSubscription = navigation.$onboardingReset
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldReset in
//                guard shouldReset else { return }
                self?.navigation.onboardingReset = false
                withAnimation {
                    self?.content = .notScanned
                }
            }
    }
    
    func reset() {
//        guard isFromMainScreen else {
//            return
//        }
        
        content = .notScanned
    }
    
    func processScannedCard(with input: OnboardingInput) {
        guard input.steps.needOnboarding else {
            processToMain()
            return
        }
        
        var input = input
        input.successCallback = processToMain
        let content: Content = .content(for: input.steps)
        
        switch content {
        case .singleCard:
            assembly.makeNoteOnboardingViewModel(with: input)
        case .twin:
            assembly.makeTwinOnboardingViewModel(with: input)
        case .wallet:
            assembly.makeWalletOnboardingViewModel(with: input)
        default:
            break
        }
        
//        withAnimation(.linear(duration: 0.0001)) {
            self.content = content
//        }
    }
    
    private func processToMain() {
        let mainModel = assembly.makeMainViewModel()
        mainModel.state = assembly.services.cardsRepository.lastScanResult
        
        if isFromMainScreen {
            navigation.mainToCardOnboarding = false
            return
        }
        
        navigation.readToMain = true
        //toMain = true
    }
    
}

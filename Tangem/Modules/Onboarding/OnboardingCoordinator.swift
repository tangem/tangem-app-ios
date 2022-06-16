//
//  OnboardingCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class OnboardingCoordinator: ObservableObject, Identifiable {    
    //MARK: - View models
    @Published var singleCardViewModel: SingleCardOnboardingViewModel? = nil
    @Published var twinsViewModel: TwinsOnboardingViewModel? = nil
    @Published var walletViewModel: WalletOnboardingViewModel? = nil
    
    //For non-dismissable presentation
    var onDismissalAttempt: () -> Void = {}
    
    func start(with input: OnboardingInput) {
        switch input.steps {
        case .singleWallet:
            singleCardViewModel = SingleCardOnboardingViewModel(input: input)
        case .twins:
            twinsViewModel = TwinsOnboardingViewModel(input: input)
        case .wallet:
            let model = WalletOnboardingViewModel(input: input)
            onDismissalAttempt = model.backButtonAction
            walletViewModel = model
        }
    }
}

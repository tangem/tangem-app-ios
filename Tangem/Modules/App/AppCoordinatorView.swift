//
//  AppCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AppCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationView {
            WelcomeView(viewModel: coordinator.welcomeViewModel)
                .sheet(item: $coordinator.tokenListCoordinator) {
                    TokenListCoordinatorView(coordinator: $0)
                }
                .sheet(item: $coordinator.mailViewModel) {
                    MailView(viewModel: $0)
                }
                .sheet(item: $coordinator.disclaimerViewModel) {
                    DisclaimerView(viewModel: $0)
                        .presentation(modal: true, onDismissalAttempt: nil, onDismissed: $0.dismissCallback)
                }
                .sheet(item: $coordinator.shopCoordinator) {
                    ShopCoordinatorView(coordinator: $0)
                }
                .navigation(item: $coordinator.pushedOnboardingCoordinator) {
                    OnboardingCoordinatorView(coordinator: $0)
                }
                .navigation(item: $coordinator.pushedWebViewModel) {
                    WebViewContainer(viewModel: $0)
                }
                .sheet(item: $coordinator.modalOnboardingCoordinator) {
                    OnboardingCoordinatorView(coordinator: $0)
                        .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                        .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                            coordinator.modalOnboardingCoordinatorKeeper = value
                        })
                }
                .sheet(item: $coordinator.sendCoordinator) {
                    SendCoordinatorView(coordinator: $0)
                }
                .sheet(item: $coordinator.modalWebViewModel) {
                    WebViewContainer(viewModel: $0)
                }
//                .navigationBarHidden(isNavigationBarHidden)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
 

//
//  WelcomeOnboardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeOnboardingView: View {
    
    @ObservedObject var viewModel: WelcomeOnboardingViewModel
    @StateObject var storiesModel = StoriesViewModel(numberOfViews: WelcomeOnboardingViewModel.StoryPage.allCases.count, storyDuration: 5)
    @EnvironmentObject var navigation: NavigationCoordinator
    
    var currentStep: WelcomeStep { .welcome }
    
    var body: some View {
        ZStack {
            StoriesView(viewModel: storiesModel) {
                if storiesModel.selection == WelcomeOnboardingViewModel.StoryPage.meetTangem.rawValue {
                    MeetTangemStoryPage()
                }
                if storiesModel.selection == WelcomeOnboardingViewModel.StoryPage.awe.rawValue {
                    AweStoryPage()
                }
                if storiesModel.selection == WelcomeOnboardingViewModel.StoryPage.backup.rawValue {
                    BackupStoryPage()
                }
                if storiesModel.selection == WelcomeOnboardingViewModel.StoryPage.currencies.rawValue {
                    CurrenciesStoryPage()
                }
                if storiesModel.selection == WelcomeOnboardingViewModel.StoryPage.web3.rawValue {
                    Web3StoryPage()
                }
                if storiesModel.selection == WelcomeOnboardingViewModel.StoryPage.finish.rawValue {
                    FinishStoryPage()
                }
            }
            .actionSheet(item: $viewModel.discardAlert, content: { $0.sheet })
            
            ScanTroubleshootingView(isPresented: $navigation.readToTroubleshootingScan) {
                self.viewModel.scanCard()
            } requestSupportAction: {
                self.viewModel.failedCardScanTracker.resetCounter()
                self.navigation.readToSendEmail = true
            }
            
            Color.clear.frame(width: 1, height: 1)
                .sheet(isPresented: $navigation.welcomeToBackup, content: {
                    OnboardingBaseView(viewModel: viewModel.assembly.getCardOnboardingViewModel())
                        .presentation(modal: viewModel.isBackupModal, onDismissalAttempt: {
                            viewModel.assembly.getWalletOnboardingViewModel()?.backButtonAction()
                        }, onDismissed: nil)
                        .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                            viewModel.isBackupModal = value
                        })
                        .environmentObject(navigation)
                })
            
            Color.clear.frame(width: 1, height: 1)
                .sheet(isPresented: $navigation.readToSendEmail, content: {
                    MailView(dataCollector: viewModel.failedCardScanTracker, support: .tangem, emailType: .failedToScanCard)
                })
            
            Color.clear.frame(width: 1, height: 1)
                .sheet(isPresented: $navigation.onboardingToDisclaimer, content: {
                    DisclaimerView(style: .sheet(acceptCallback: viewModel.acceptDisclaimer), showAccept: true)
                        .presentation(modal: true, onDismissalAttempt: nil, onDismissed: viewModel.disclaimerDismissed)
                })
            
            Color.clear.frame(width: 1, height: 1)
                .sheet(isPresented: $navigation.readToShop, content: {
                    WebViewContainer(url: Constants.shopURL, title: "home_button_shop", withCloseButton: true)
                })
        }
        .alert(item: $viewModel.error, content: { $0.alert })
        .onAppear(perform: viewModel.onAppear)
    }
}

struct WelcomeOnboardingView_Previews: PreviewProvider {
    
    static let assembly: Assembly = .previewAssembly
    
    static var previews: some View {
        WelcomeOnboardingView(viewModel: assembly.getLetsStartOnboardingViewModel(with: { _ in }))
            .environmentObject(assembly.services.navigationCoordinator)
    }
}

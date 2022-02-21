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
    @ObservedObject var storiesModel: StoriesViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    var currentStep: WelcomeStep { .welcome }
    
    private let lightStories: [WelcomeStoryPage] = [
        .backup,
        .currencies,
        .web3,
    ]
    
    var body: some View {
        ZStack {
            StoriesView(viewModel: storiesModel) {
                switch storiesModel.selection {
                case WelcomeStoryPage.meetTangem.rawValue:
                    MeetTangemStoryPage(
                        progress: $storiesModel.currentProgress,
                        immediatelyShowButtons: viewModel.didDisplayMainScreenStories,
                        scanCard: scanCard,
                        orderCard: orderCard
                    )
                case WelcomeStoryPage.awe.rawValue:
                    AweStoryPage(scanCard: scanCard, orderCard: orderCard)
                case WelcomeStoryPage.backup.rawValue:
                    BackupStoryPage(scanCard: scanCard, orderCard: orderCard)
                case WelcomeStoryPage.currencies.rawValue:
                    CurrenciesStoryPage(scanCard: scanCard, orderCard: orderCard)
                case WelcomeStoryPage.web3.rawValue:
                    Web3StoryPage(scanCard: scanCard, orderCard: orderCard)
                case WelcomeStoryPage.finish.rawValue:
                    FinishStoryPage(scanCard: scanCard, orderCard: orderCard)
                default:
                    EmptyView()
                }
            }
            .statusBar(hidden: true)
            .environment(\.colorScheme, lightStories.map { $0.rawValue }.contains(storiesModel.selection) ? .light : .dark)
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
                    NavigationView {
                        ShopContainerView(viewModel: viewModel.assembly.makeShopViewModel())
                            .environmentObject(navigation)
                    }
                })
        }
        .alert(item: $viewModel.error, content: { $0.alert })
        .onAppear(perform: viewModel.onAppear)
    }
    
    private func scanCard() {
        viewModel.scanCard()
    }
    
    private func orderCard() {
        navigation.readToShop = true
        Analytics.log(.getACard, params: [.source: .welcome])
    }
}

struct WelcomeOnboardingView_Previews: PreviewProvider {
    
    static let assembly: Assembly = .previewAssembly
    
    static var previews: some View {
        WelcomeOnboardingView(viewModel: assembly.getLetsStartOnboardingViewModel(with: { _ in }), storiesModel: assembly.makeWelcomeStoriesModel())
            .environmentObject(assembly.services.navigationCoordinator)
    }
}

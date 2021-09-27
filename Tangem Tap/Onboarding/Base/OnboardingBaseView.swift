//
//  OnboardingBaseView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingBaseView: View {
    
    @ObservedObject var viewModel: OnboardingBaseViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    @ViewBuilder
    var navigationLinks: some View {
        if !viewModel.isFromMainScreen {
            NavigationLink(destination: MainView(viewModel: viewModel.assembly.makeMainViewModel()),
                           isActive: $viewModel.toMain)
        }
        
        NavigationLink(destination: EmptyView(), isActive: .constant(false))
    }
    
    @ViewBuilder
    var notScannedContent: some View {
        Text("Not scanned view")
    }
    
    @ViewBuilder
    var defaultLaunchView: some View {
        SingleCardOnboardingView(viewModel: viewModel.assembly.getOnboardingViewModel())
    }
    
    @ViewBuilder
    var content: some View {
        switch viewModel.content {
        case .notScanned:
            if viewModel.isFromMainScreen {
                defaultLaunchView
                    .transition(.withoutOpcaity)
            } else {
                WelcomeOnboardingView(viewModel: viewModel.assembly.getLetsStartOnboardingViewModel(with: viewModel.processScannedCard(with:)))
                    .transition(.withoutOpcaity)
            }
        case .singleCard:
            defaultLaunchView
                .transition(.withoutOpcaity)
        case .twin:
            TwinsOnboardingView(viewModel: viewModel.assembly.getTwinsOnboardingViewModel())
                .transition(.withoutOpcaity)
        case .wallet:
            WalletOnboardingView(viewModel: viewModel.assembly.getWalletOnboardingViewModel())
                .transition(.withoutOpcaity)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                navigationLinks
                
                content
            }
            .navigationBarTitle(viewModel.content.navbarTitle, displayMode: .inline)
//            .navigationBarHidden(
//                !navigation.onboardingToBuyCrypto &&
//                    !navigation.readToShop
//            )
        }
        .onAppear(perform: {
            viewModel.bind()
        })
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
    }
}

struct CardOnboardingView_Previews: PreviewProvider {
    
    static let assembly = Assembly.previewAssembly
    
    static var previews: some View {
        OnboardingBaseView(
//            viewModel: assembly.makeCardOnboardingViewModel(with: assembly.previewTwinOnboardingInput)
            viewModel: assembly.getLaunchOnboardingViewModel()
        )
        .environmentObject(assembly.services.navigationCoordinator)
    }
}

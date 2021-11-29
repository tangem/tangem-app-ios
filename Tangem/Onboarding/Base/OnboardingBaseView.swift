//
//  OnboardingBaseView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingBaseView: View {
    @ObservedObject var viewModel: OnboardingBaseViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    var isModal: Bool = false
    
    @ViewBuilder
    var navigationLinks: some View {
        if !viewModel.isFromMainScreen {
            NavigationLink(destination: MainView(viewModel: viewModel.assembly.makeMainViewModel()),
                           isActive: $navigation.readToMain)
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
                    .transition(.withoutOpacity)
            } else {
                WelcomeOnboardingView(viewModel: viewModel.assembly.getLetsStartOnboardingViewModel(with: viewModel.processScannedCard(with:)))
                    .transition(.withoutOpacity)
            }
        case .singleCard:
            defaultLaunchView
                .transition(.withoutOpacity)
        case .twin:
            TwinsOnboardingView(viewModel: viewModel.assembly.getTwinsOnboardingViewModel())
                .transition(.withoutOpacity)
        case .wallet:
            WalletOnboardingView(viewModel: viewModel.assembly.getWalletOnboardingViewModel())
                .transition(.withoutOpacity)
        }
    }
    
    var isNavigationBarHidden: Bool {
        if navigation.readToMain {
            return false
        }
        
        return !(navigation.readToShop
                    || navigation.onboardingToBuyCrypto
                    || navigation.onboardingWalletToShop)
    }
    
    var body: some View {
        ZStack {
            navigationLinks
            
            if isModal {
                NavigationView {
                content
                    .navigationBarTitle(viewModel.content.navbarTitle, displayMode: .inline)
                    .navigationBarHidden(true)
                }
            } else {
                content
                    .navigationBarTitle(viewModel.content.navbarTitle, displayMode: .inline)
            }
            //NavigationView {
//                content
//                    .navigationBarTitle(viewModel.content.navbarTitle, displayMode: .inline)
                //            .navigationBarHidden(
                //                !navigation.onboardingToBuyCrypto &&
                //                    !navigation.readToShop
                //            )
            //}
        }
        .onAppear(perform: {
            viewModel.bind()
        })
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(isNavigationBarHidden)
        //.navigationBarHidden(true)
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

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
        ZStack {
            NavigationView {
                WelcomeView(viewModel: coordinator.welcomeViewModel)
                    .navigation(item: $coordinator.pushedOnboardingCoordinator) {
                        OnboardingCoordinatorView(coordinator: $0)
                    }
                    .navigation(item: $coordinator.pushedWebViewModel) {
                        WebViewContainer(viewModel: $0)
                    }
                    .navigation(item: $coordinator.detailsViewModel) {
                        DetailsView(viewModel: $0)
                    }
                    .navigation(item: $coordinator.tokenDetailsViewModel) {
                        TokenDetailsView(viewModel: $0)
                    }
                    .navigation(item: $coordinator.currencySelectViewModel) {
                        CurrencySelectView(viewModel: $0)
                    }
                    .navigation(item: $coordinator.walletConnectViewModel) {
                        WalletConnectView(viewModel: $0)
                    }
                    .navigation(item: $coordinator.cardOperationViewModel) {
                        CardOperationView(viewModel: $0)
                    }
                    .navigation(item: $coordinator.secManagementViewModel) {
                        SecurityManagementView(viewModel: $0)
                    }
                
                //                .navigationBarHidden(isNavigationBarHidden)
            }
            
            sheets
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    @ViewBuilder
    private var sheets: some View {
        VStack {
            SheetHolder()
                .sheet(item: $coordinator.disclaimerViewModel) {
                    DisclaimerView(viewModel: $0)
                        .presentation(modal: true, onDismissalAttempt: nil, onDismissed: $0.dismissCallback)
                }
            
            SheetHolder()
                .sheet(item: $coordinator.shopCoordinator) {
                    ShopCoordinatorView(coordinator: $0)
                }
            
            SheetHolder()
                .sheet(item: $coordinator.tokenListCoordinator) {
                    TokenListCoordinatorView(coordinator: $0)
                }
            
            SheetHolder()
                .sheet(item: $coordinator.mailViewModel) {
                    MailView(viewModel: $0)
                }
            
            SheetHolder()
                .sheet(item: $coordinator.modalOnboardingCoordinator) {
                    OnboardingCoordinatorView(coordinator: $0)
                        .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                        .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                            coordinator.modalOnboardingCoordinatorKeeper = value
                        })
                }
            
            SheetHolder()
                .sheet(item: $coordinator.sendCoordinator) {
                    SendCoordinatorView(coordinator: $0)
                }
            
            SheetHolder()
                .sheet(item: $coordinator.modalWebViewModel) {
                    WebViewContainer(viewModel: $0)
                }
            
            SheetHolder()
                .sheet(item: $coordinator.pushTxCoordinator) {
                    PushTxCoordinatorView(coordinator: $0)
                }
            
            SheetHolder()
                .sheet(item: $coordinator.safariURL) {
                    SafariView(url: $0)
                }
            
            SheetHolder()
                .sheet(item: $coordinator.qrScanViewModel) {
                    QRScanView(viewModel: $0)
                        .edgesIgnoringSafeArea(.all)
                }
            
            BottomSheetView(isPresented: coordinator.$qrBottomSheetKeeper,
                            hideBottomSheetCallback: coordinator.hideQrBottomSheet,
                            content: { addressQrBottomSheetContent })
        }
    }
    
    @ViewBuilder
    private var addressQrBottomSheetContent: some View {
        if let model = coordinator.addressQrBottomSheetContentViewVodel {
            AddressQrBottomSheetContent(viewModel: model)
        }
    }
}

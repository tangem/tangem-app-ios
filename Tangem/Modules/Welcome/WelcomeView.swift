//
//  WelcomeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: WelcomeViewModel

    var body: some View {
        ZStack {
            if viewModel.showingAuthentication {
                authenticationView
            } else {
                storiesView
            }

            ScanTroubleshootingView(isPresented: $viewModel.showTroubleshootingView,
                                    tryAgainAction: viewModel.tryAgain,
                                    requestSupportAction: viewModel.requestSupport)
        }
        .navigationBarHidden(viewModel.navigationBarHidden)
        .navigationBarTitle("", displayMode: .inline)
        .actionSheet(item: $viewModel.discardAlert, content: { $0.sheet })
        .alert(item: $viewModel.error, content: { $0.alert })
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDissappear)
    }

    var authenticationView: some View {
        VStack(spacing: 0) {
            Spacer()

            Assets.tangemIconBig
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .foregroundColor(Colors.Text.primary1)
                .padding(.bottom, 48)

            Text("Unlock your wallet")
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .padding(.bottom, 14)

            Text("To unlock your wallet use biometric authentication or scan a card")
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            #warning("TOUCH ID?")
            TangemButton(title: "Unlock with Face ID") {
                viewModel.tryBiometricAuthentication()
            }
            .buttonStyle(TangemButtonStyle(colorStyle: .grayAlt3, layout: .flexibleWidth, isLoading: viewModel.isScanningCard))
            .padding(.bottom, 11)

            TangemButton(title: "Unlock with card", image: "tangemIconWhite", iconPosition: .trailing) {
                viewModel.unlockWithCard()
            }
            .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth, isLoading: viewModel.isScanningCard))
        }
        .padding()
    }

    var storiesView: some View {
        StoriesView(viewModel: viewModel.storiesModel) { // [REDACTED_TODO_COMMENT]
            viewModel.storiesModel.currentStoryPage(
                isScanning: viewModel.isScanningCard,
                scanCard: viewModel.scanCard,
                orderCard: viewModel.orderCard,
                searchTokens: viewModel.openTokensList
            )
        }
        .statusBar(hidden: true)
        .environment(\.colorScheme, viewModel.storiesModel.currentPage.colorScheme)
    }
}

struct WelcomeOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(viewModel: WelcomeViewModel(coordinator: WelcomeCoordinator()))
    }
}

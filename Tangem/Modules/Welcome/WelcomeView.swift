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
                unlockView
            } else {
                storiesView
            }
        }
        .navigationBarHidden(viewModel.navigationBarHidden)
        .navigationBarTitle("", displayMode: .inline)
        .actionSheet(item: $viewModel.discardAlert, content: { $0.sheet })
        .alert(item: $viewModel.error, content: { $0.alert })
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDissappear)
        .background(
            ScanTroubleshootingView(isPresented: $viewModel.showTroubleshootingView,
                                    tryAgainAction: viewModel.tryAgain,
                                    requestSupportAction: viewModel.requestSupport)
        )
    }

    var unlockView: some View {
        VStack(spacing: 0) {
            Spacer()

            Assets.tangemIconBig
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .foregroundColor(Colors.Text.primary1)
                .padding(.bottom, 48)

            Text("welcome_unlock_title")
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .padding(.bottom, 14)

            Text("welcome_unlock_description".localized(BiometricAuthorizationUtils.biometryType.name))
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            TangemButton(title: viewModel.unlockWithBiometryLocalizationKey, action: viewModel.unlockWithBiometry)
                .buttonStyle(TangemButtonStyle(colorStyle: .grayAlt3, layout: .flexibleWidth, isLoading: viewModel.isScanningCard))
                .padding(.bottom, 11)

            TangemButton(title: "welcome_unlock_card", image: "tangemIconWhite", iconPosition: .trailing, action: viewModel.unlockWithCard)
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

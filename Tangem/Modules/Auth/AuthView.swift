//
//  AuthView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct AuthView: View {
    @ObservedObject private var viewModel: AuthViewModel

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        unlockView
            .navigationBarHidden(viewModel.navigationBarHidden)
            .navigationBarTitle("", displayMode: .inline)
            .alert(item: $viewModel.error, content: { $0.alert })
            .onAppear(perform: viewModel.onAppear)
            .onDidAppear(viewModel.onDidAppear)
            .onDisappear(perform: viewModel.onDisappear)
            .background(
                ScanTroubleshootingView(isPresented: $viewModel.showTroubleshootingView,
                                        tryAgainAction: viewModel.tryAgain,
                                        requestSupportAction: viewModel.requestSupport)
            )
    }

    private var unlockView: some View {
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
}

struct AuthView_Preview: PreviewProvider {
    static let viewModel = AuthViewModel(coordinator: AuthCoordinator())

    static var previews: some View {
        AuthView(viewModel: viewModel)
    }
}

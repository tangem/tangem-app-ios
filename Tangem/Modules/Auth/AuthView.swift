//
//  AuthView.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.11.2022.
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

            MainButton(
                title: .string(viewModel.unlockWithBiometryButtonTitle),
                style: .secondary,
                isLoading: viewModel.isScanningCard,
                action: viewModel.unlockWithBiometry
            )
            .padding(.bottom, 11)

            MainButton(
                title: .string("welcome_unlock_card".localized),
                icon: .trailing(Assets.tangemIcon),
                style: .primary,
                isLoading: viewModel.isScanningCard,
                action: viewModel.unlockWithCard
            )
        }
        .padding()
    }
}

struct AuthView_Preview: PreviewProvider {
    static let viewModel = AuthViewModel(unlockOnStart: false, coordinator: AuthCoordinator())

    static var previews: some View {
        AuthView(viewModel: viewModel)
    }
}

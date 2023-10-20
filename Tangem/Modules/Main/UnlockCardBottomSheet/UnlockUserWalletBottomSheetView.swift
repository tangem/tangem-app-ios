//
//  UnlockUserWalletBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct UnlockUserWalletBottomSheetView: View {
    @ObservedObject var viewModel: UnlockUserWalletBottomSheetViewModel

    var body: some View {
        VStack(spacing: 0) {
            Assets.lockBig.image
                .foregroundColor(Colors.Icon.primary1)
                .padding(.top, 46)
                .padding(.bottom, 30)

            Text(Localization.commonAccessDenied)
                .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                .padding(.bottom, 14)

            Text(Localization.unlockWalletDescriptionFull(BiometricAuthorizationUtils.biometryType.name))
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 56)
                .padding(.horizontal, 34)

            MainButton(
                title: Localization.userWalletListUnlockAllWith(BiometricAuthorizationUtils.biometryType.name),
                action: viewModel.unlockWithBiometry
            )
            .padding(.bottom, 10)

            MainButton(
                title: Localization.welcomeUnlockCard,
                icon: .trailing(Assets.tangemIcon),
                style: .secondary,
                isLoading: viewModel.isScannerBusy,
                action: viewModel.unlockWithCard
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .alert(item: $viewModel.error) { $0.alert }
        .background(
            ScanTroubleshootingView(
                isPresented: $viewModel.showTroubleshootingView,
                tryAgainAction: viewModel.unlockWithCard,
                requestSupportAction: viewModel.requestSupport
            )
        )
    }
}

struct UnlockUserWalletBottomSheetView_Previews: PreviewProvider {
    class FakeUnlockUserWalletDelegate: UnlockUserWalletBottomSheetDelegate {
        func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType) {
            print("Open mail")
        }

        func unlockedWithBiometry() {
            print("Unlocked with biometry")
        }

        func userWalletUnlocked(_ userWalletModel: UserWalletModel) {
            print("Unlocked with card: \(userWalletModel.userWalletId.stringValue)")
        }
    }

    static let delegate = FakeUnlockUserWalletDelegate()
    static var bottomSheetModel: UnlockUserWalletBottomSheetViewModel = {
        let lockedUserWalletModel = FakeUserWalletModel.twins
        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [lockedUserWalletModel])

        return UnlockUserWalletBottomSheetViewModel(
            userWalletModel: lockedUserWalletModel,
            delegate: delegate
        )
    }()

    static var previews: some View {
        StatefulPreviewWrapper(UnlockUserWalletBottomSheetViewModel?.none, content: { state in
            VStack {
                Button("Open bottom sheet") {
                    state.wrappedValue = bottomSheetModel
                }

                NavHolder()
                    .bottomSheet(item: state, settings: .init(backgroundColor: Colors.Background.primary)) { model in
                        UnlockUserWalletBottomSheetView(viewModel: model)
                    }
            }
            .onAppear {
                state.wrappedValue = bottomSheetModel
            }
        })
    }
}

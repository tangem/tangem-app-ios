//
//  OnrampKYCVerificationSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

struct OnrampKYCVerificationSheetView: View {
    @ObservedObject var viewModel: OnrampKYCVerificationSheetViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content

            NavigationBarButton.close(action: viewModel.close)
                .padding(.all, 16)
        }
    }

    private var content: some View {
        VStack(spacing: .zero) {
            VStack(spacing: 24) {
                iconSection

                VStack(spacing: 8) {
                    Text(Localization.onrampKycVerificationTitle)
                        .style(Fonts.BoldStatic.title3, color: Colors.Text.primary1)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(Localization.onrampKycVerificationSubtitle(viewModel.providerName))
                        .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)
            }
            .padding(.top, 50)
            .padding(.bottom, 24)
            .padding(.horizontal, 16)

            whatsImportantSection
                .padding(.horizontal, 16)
                .padding(.bottom, 24)

            VStack(spacing: 8) {
                MainButton(
                    title: Localization.onrampKycVerificationVerifyButton,
                    style: .primary,
                    action: viewModel.verify
                )

                MainButton(
                    title: Localization.onrampKycVerificationChooseAnother,
                    style: .secondary,
                    action: viewModel.chooseAnotherMethod
                )
            }
            .padding(.all, 16)
        }
        .infinityFrame(axis: .horizontal)
    }

    private var iconSection: some View {
        Assets.Kyc.identityDocument.image
            .renderingMode(.template)
            .resizable()
            .frame(width: 32, height: 32)
            .foregroundStyle(Colors.Icon.accent)
            .padding(12)
            .background(Circle().fill(Colors.Icon.accent.opacity(0.1)))
    }

    private var whatsImportantSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.onrampKycVerificationWhatsImportant)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Separator(height: .minimal, color: Colors.Stroke.primary)

            VStack(alignment: .leading, spacing: 8) {
                bulletItem(Localization.onrampKycVerificationBulletFree)
                bulletItem(Localization.onrampKycVerificationBulletUnlocks)
                bulletItem(Localization.onrampKycVerificationBulletPrivacy)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Colors.Background.action)
        )
    }

    private func bulletItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(AppConstants.dotSign)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

            Text(text)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Previews

#Preview {
    final class OnrampKYCVerificationSheetRoutableMock: OnrampKYCVerificationSheetRoutable {
        func onChooseAnother() {}
        func onProceedToWidget() {}
        func onClose() {}
    }

    return OnrampKYCVerificationSheetView(
        viewModel: OnrampKYCVerificationSheetViewModel(
            providerName: "MoonPay",
            routable: OnrampKYCVerificationSheetRoutableMock()
        )
    )
}

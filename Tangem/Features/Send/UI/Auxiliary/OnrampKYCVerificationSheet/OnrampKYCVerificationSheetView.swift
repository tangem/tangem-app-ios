//
//  OnrampKYCVerificationSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAccessibilityIdentifiers
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
                        .style(Fonts.BoldStatic.title3, color: DesignSystem.Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(Localization.onrampKycVerificationSubtitle(viewModel.providerName))
                        .style(Fonts.Regular.subheadline, color: DesignSystem.Color.textSecondary)
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
            .foregroundStyle(DesignSystem.Color.iconAccentBlue)
            .padding(12)
            .background(Circle().fill(DesignSystem.Color.bgAccentBlueSubtle))
            .accessibilityIdentifier(OnrampAccessibilityIdentifiers.kycIcon)
    }

    private var whatsImportantSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.onrampKycVerificationWhatsImportant)
                .style(Fonts.Bold.footnote, color: DesignSystem.Color.textSecondary)

            Separator(height: .minimal, color: DesignSystem.Color.borderSecondary)

            VStack(alignment: .leading, spacing: 8) {
                bulletItem(Localization.onrampKycVerificationBulletFree)
                bulletItem(Localization.onrampKycVerificationBulletUnlocks)
                bulletItem(Localization.onrampKycVerificationBulletPrivacy)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(DesignSystem.Color.bgSecondary)
        )
    }

    private func bulletItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(AppConstants.dotSign)
                .style(Fonts.Regular.footnote, color: DesignSystem.Color.textPrimary)

            Text(text)
                .style(Fonts.Regular.footnote, color: DesignSystem.Color.textPrimary)
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

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

struct OnrampKYCVerificationSheetView: View {
    @ObservedObject var viewModel: OnrampKYCVerificationSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            OnrampSheetHeaderView(closeAction: viewModel.close)

            ModalStatus(
                .info,
                title: Localization.onrampKycVerificationTitle,
                description: Localization.onrampKycVerificationSubtitle(viewModel.providerName)
            )

            whatsImportantSection

            Footer(.buttons(
                primary: TangemUI.Button(
                    label: Localization.onrampKycVerificationVerifyButton,
                    accessibilityLabel: nil,
                    action: viewModel.verify
                )
                .styleType(.primary),
                secondary: TangemUI.Button(
                    label: Localization.onrampKycVerificationChooseAnother,
                    accessibilityLabel: nil,
                    action: viewModel.chooseAnotherMethod
                )
                .styleType(.secondary(.default))
            ))
        }
        .frame(maxWidth: .infinity)
    }

    private var whatsImportantSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.onrampKycVerificationWhatsImportant)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .padding(.vertical, 12)

            importantItem(Localization.onrampKycVerificationBulletFree)
            importantItem(Localization.onrampKycVerificationBulletUnlocks)
            importantItem(Localization.onrampKycVerificationBulletPrivacy)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    private func importantItem(_ text: String) -> some View {
        Text(text)
            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 12)
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

//
//  TangemPayVirtualAccountSuccessView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

// [REDACTED_TODO_COMMENT]
struct TangemPayVirtualAccountSuccessView: View {
    @ObservedObject var viewModel: TangemPayVirtualAccountSuccessViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            background

            content

            closeButton
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.30, green: 0.40, blue: 0.10),
                Color.black,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            DesignSystem.Icons.Checkmark.regular24.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(.white)
                .padding(12)
                .overlay(Circle().strokeBorder(.white.opacity(0.4)))

            Text(Localization.tangempayBankTransferSuccessTitle)
                .font(token: DesignSystem.Font.headingMediumToken)
                .foregroundStyle(.white)

            Text(Localization.tangempayBankTransferSuccessSubtitle)
                .font(token: DesignSystem.Font.headingMediumToken)
                .foregroundStyle(.white.opacity(0.4))

            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 80)
    }

    private var closeButton: some View {
        TangemButtonV2(
            label: AttributedString(Localization.commonClose),
            accessibilityLabel: Localization.commonClose,
            action: viewModel.close
        )
        .size(.x14)
        .horizontalLayout(.infinity)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

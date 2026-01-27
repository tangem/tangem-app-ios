//
//  TangemPayAddToAppPayGuideView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayAddToAppPayGuideView: View {
    @ObservedObject var viewModel: TangemPayAddToAppPayGuideViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    TangemPayCardDetailsView(viewModel: viewModel.tangemPayCardDetailsViewModel)

                    steps
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .withCloseButton(
                placement: .topBarTrailing,
                style: .crossImage,
                action: viewModel.close
            )
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    MainButton(
                        title: Localization.commonGotIt,
                        style: .secondary,
                        action: viewModel.close
                    )

                    MainButton(
                        title: Localization.tangempayCardDetailsOpenWalletStep1Apple,
                        style: .primary,
                        action: viewModel.openAppleWalletApp
                    )
                }
                .padding(16)
            }
        }
    }

    var steps: some View {
        VStack(spacing: 24) {
            Text(Localization.tangempayCardDetailsOpenWalletTitleApple)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                step(number: "1", text: Localization.tangempayCardDetailsOpenWalletStep1Apple)
                step(number: "2", text: Localization.tangempayCardDetailsOpenWalletStep15Apple)
                step(number: "3", text: Localization.tangempayCardDetailsOpenWalletStep2Apple)
                step(number: "4", text: Localization.tangempayCardDetailsOpenWalletStep3)
                step(number: "5", text: Localization.tangempayCardDetailsOpenWalletStep4)
                step(number: "6", text: Localization.tangempayCardDetailsOpenWalletStep5)
            }
            .padding(.horizontal, 24)
        }
    }

    func step(number: String, text: String) -> some View {
        HStack(spacing: 16) {
            Text(number)
                .style(Fonts.Bold.footnote, color: Colors.Text.constantWhite)
                .background {
                    Circle()
                        .foregroundStyle(Colors.Text.accent)
                        .frame(minWidth: 24, minHeight: 24)
                }

            Text(text)
                .style(Fonts.Bold.callout, color: Colors.Text.primary1)
                .multilineTextAlignment(.leading)
        }
    }
}

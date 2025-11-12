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
        NavigationView {
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
            .withCloseButton(placement: .topBarTrailing, style: .crossImage) {
                dismiss()
            }
            .safeAreaInset(edge: .bottom) {
                bottomButton
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
                step(number: "1", text: openAppleWalletAttributedString, action: {
                    viewModel.openAppleWalletApp()
                })

                step(number: "2", text: defaultAttributedString(Localization.TangempayCardDetailsOpenWalletStep1._5Apple))
                step(number: "3", text: defaultAttributedString(Localization.tangempayCardDetailsOpenWalletStep2Apple))
                step(number: "4", text: defaultAttributedString(Localization.tangempayCardDetailsOpenWalletStep3))
                step(number: "5", text: defaultAttributedString(Localization.tangempayCardDetailsOpenWalletStep4))
                step(number: "6", text: defaultAttributedString(Localization.tangempayCardDetailsOpenWalletStep5))
            }
            .padding(.horizontal, 24)
        }
    }

    var bottomButton: some View {
        MainButton(title: "Got it", style: .primary) {
            dismiss()
        }
    }

    @ViewBuilder
    func step(number: String, text: AttributedString, action: (() -> Void)? = nil) -> some View {
        if let action {
            Button(
                action: action,
                label: {
                    stepContent(number: number, text: text)
                }
            )
        } else {
            stepContent(number: number, text: text)
        }
    }

    func stepContent(number: String, text: AttributedString) -> some View {
        HStack(spacing: 16) {
            Text(number)
                .style(Fonts.Bold.footnote, color: Colors.Text.constantWhite)
                .background {
                    Circle()
                        .foregroundStyle(Colors.Text.accent)
                        .frame(minWidth: 24, minHeight: 24)
                }

            Text(text)
                .multilineTextAlignment(.leading)
        }
    }

    var openAppleWalletAttributedString: AttributedString {
        var open = AttributedString(Localization.tangempayCardDetailsOpenWalletStep1AppleOpen + " ")
        open.foregroundColor = Colors.Text.primary1
        open.font = Fonts.Bold.callout

        var appleWallet = AttributedString(Localization.tangempayCardDetailsOpenWalletStep1AppleWallet)
        appleWallet.foregroundColor = Colors.Text.accent
        appleWallet.font = Fonts.Regular.callout

        return open + appleWallet
    }

    func defaultAttributedString(_ string: String) -> AttributedString {
        var result = AttributedString(string)
        result.foregroundColor = Colors.Text.primary1
        result.font = Fonts.Bold.callout

        return result
    }

    func dismiss() {
        viewModel.onDismiss()
    }
}

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

struct TangemPayAddToAppPayGuideView: View {
    @ObservedObject var viewModel: TangemPayAddToAppPayGuideViewModel
    @Environment(\.dismiss) var dismissAction

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
            .onAppear {
                viewModel.onAppear()
            }
        }
    }

    // [REDACTED_TODO_COMMENT]
    var steps: some View {
        VStack(spacing: 24) {
            Text("Add card to Apple Pay")
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                step(number: "1", text: openAppleWalletAttributedString, action: {
                    viewModel.openAppleWalletApp()
                })

                step(number: "2", text: defaultAttributedString("Tap “+” button on the top right"))
                step(number: "3", text: defaultAttributedString("Tap “Debit or Credit Card”"))
                step(number: "4", text: defaultAttributedString("Enter card details manually"))
                step(number: "5", text: defaultAttributedString("Verify card using the OTP sent to your device."))
                step(number: "6", text: defaultAttributedString("All set! Your card is ready to use."))
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
        var open = AttributedString("Open ")
        open.foregroundColor = Colors.Text.primary1
        open.font = Fonts.Bold.callout

        var appleWallet = AttributedString("Apple Wallet")
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
        dismissAction()
    }
}

//
//  MobileOnboardingSuccessView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization
import TangemAccessibilityIdentifiers

struct MobileOnboardingSuccessView: View {
    typealias ViewModel = MobileOnboardingSuccessViewModel

    let viewModel: ViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            infoView(viewModel.infoItem)
            Spacer()
            actionButtonsStack
        }
        .onFirstAppear(perform: viewModel.onFirstAppear)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .stepsFlowNavBar(title: viewModel.navigationTitle)
    }
}

// MARK: - Subviews

extension MobileOnboardingSuccessView {
    func infoView(_ item: ViewModel.InfoItem) -> some View {
        VStack(spacing: 20) {
            item.icon.image

            VStack(spacing: 12) {
                Text(item.title)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)

                Text(item.description)
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    var actionButtonsStack: some View {
        VStack(spacing: 12) {
            if let applePayAction = viewModel.applePayAction {
                applePayButton(action: applePayAction)
            }

            actionButton(viewModel.actionItem)
        }
    }

    func actionButton(_ item: ViewModel.ActionItem) -> some View {
        MainButton(
            title: item.title,
            style: viewModel.applePayAction == nil ? .primary : .secondary,
            action: item.action
        )
        .accessibilityIdentifier(viewModel.actionButtonAccessibilityIdentifier)
    }

    func applePayButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(Localization.onboardingButtonBuyWith)
                    .style(Fonts.Bold.callout, color: .white)

                HStack(spacing: 1) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)

                    Text("Pay")
                        .style(Fonts.Bold.callout, color: .white)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46)
            .background(Color.black)
            .cornerRadiusContinuous(14)
        }
        .buttonStyle(BorderlessButtonStyle())
        .accessibilityLabel("\(Localization.onboardingButtonBuyWith) Apple Pay")
        .accessibilityIdentifier(OnboardingAccessibilityIdentifiers.mobileOnboardingSuccessApplePayButton)
    }
}

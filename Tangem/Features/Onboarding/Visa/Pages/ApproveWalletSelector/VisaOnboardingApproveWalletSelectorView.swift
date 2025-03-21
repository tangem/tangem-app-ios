//
//  VisaOnboardingApproveWalletSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct VisaOnboardingApproveWalletSelectorView: View {
    @ObservedObject var viewModel: VisaOnboardingApproveWalletSelectorViewModel

    var body: some View {
        VStack(spacing: 0) {
            NotificationView(input: viewModel.instructionNotificationInput)
                .padding(.horizontal, 16)

            walletList

            Spacer()

            MainButton(title: Localization.commonContinue, action: viewModel.continueAction)
                .padding(.horizontal, 16)
        }
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var walletList: some View {
        VStack(spacing: 10) {
            Text(Localization.visaOnboardingWalletListHeader)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            ForEach(VisaOnboardingApproveWalletSelectorItemView.Option.allCases) { option in
                VisaOnboardingApproveWalletSelectorItemView(
                    item: option,
                    selected: viewModel.selectedOption == option,
                    tapAction: {
                        viewModel.selectOption(option)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }
}

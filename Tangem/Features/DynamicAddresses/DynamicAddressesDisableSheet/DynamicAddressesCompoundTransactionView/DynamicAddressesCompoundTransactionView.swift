//
//  DynamicAddressesCompoundTransactionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization

struct DynamicAddressesCompoundTransactionView: View {
    @ObservedObject var viewModel: DynamicAddressesCompoundTransactionViewModel

    var body: some View {
        VStack(spacing: 14) {
            GroupedSection(viewModel.feeCompactViewModel) {
                FeeCompactView(viewModel: $0, tapAction: nil)
            } footer: {
                DefaultFooterView(Localization.dynamicAddressesDisableFeeDescription)
                    .padding(.horizontal, 16)
            }
            .horizontalPadding(0)

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .setButtonsLoadingState(to: viewModel.notificationButtonIsLoading)
            }

            if viewModel.needsHoldToConfirm {
                HoldToConfirmButton(
                    title: Localization.commonConfirm,
                    isLoading: viewModel.isLoading,
                    isDisabled: false,
                    action: viewModel.confirm
                )
            } else {
                MainButton(
                    title: Localization.commonConfirm,
                    icon: viewModel.mainButtonIcon,
                    isLoading: viewModel.isLoading,
                    action: viewModel.confirm
                )
            }
        }
    }
}

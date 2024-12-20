//
//  OnrampProvidersView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampProvidersView: View {
    @ObservedObject private var viewModel: OnrampProvidersViewModel

    init(viewModel: OnrampProvidersViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 22) {
            headerView

            GroupedScrollView(spacing: 0) {
                paymentSection

                FixedSpacer(height: 22)

                providersSection
            }

            ExpressMoreProvidersSoonView()
        }
        .background(Colors.Background.primary.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear(perform: viewModel.onAppear)
    }

    private var headerView: some View {
        BottomSheetHeaderView(
            title: Localization.expressChooseProvidersTitle,
            subtitle: Localization.onrampChooseProviderTitleHint,
            leading: {
                CloseButton(dismiss: viewModel.closeView)
            }
        )
        .padding(.top, 8)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var paymentSection: some View {
        if let data = viewModel.paymentViewData {
            OnrampProvidersPaymentView(data: data)
        }
    }

    @ViewBuilder
    private var providersSection: some View {
        ExpressProvidersList(providersViewData: viewModel.providersViewData)
    }
}

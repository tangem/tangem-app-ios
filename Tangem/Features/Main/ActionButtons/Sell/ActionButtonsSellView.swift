//
//  ActionButtonsSellView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct ActionButtonsSellView: View {
    @ObservedObject var viewModel: ActionButtonsSellViewModel

    var body: some View {
        TokenSelectorView(viewModel: viewModel.tokenSelectorViewModel) {
            TokenSelectorEmptyContentView(message: Localization.actionButtonsSellEmptySearchMessage)
        } headerContent: {
            notifications
        }
        .searchType(.native)
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .navigationTitle(Localization.commonSell)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut, value: viewModel.notificationInput)
        .toolbar {
            NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
        }
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var notifications: some View {
        if let notification = viewModel.notificationInput {
            NotificationView(input: notification)
                .transition(.notificationTransition)
        }
    }
}

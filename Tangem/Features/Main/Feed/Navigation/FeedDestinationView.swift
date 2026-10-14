//
//  FeedDestinationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct FeedDestinationView: View {
    let destination: FeedDestination

    var body: some View {
        switch destination {
        case .referral(let coordinator):
            NavigationStack {
                ReferralCoordinatorView(coordinator: coordinator)
                    .withCloseButton(placement: .topBarTrailing, style: .icon, action: coordinator.dismiss)
            }
        case .forYou(let coordinator):
            ForYouCoordinatorView(coordinator: coordinator)
                .background(FeedPopGestureEnabler())
                .toolbar(.hidden, for: .navigationBar)
        case .accountForm(let viewModel):
            NavigationStack { AccountFormView(viewModel: viewModel) }
                .presentation(onDismissalAttempt: viewModel.onClose)
                .presentationCornerRadius(Constants.accountFormCornerRadius)
        case .jointAccount(let coordinator):
            JointAccountManagementCoordinatorView(coordinator: coordinator)
        case .token(let coordinator):
            MarketsTokenDetailsCoordinatorView(coordinator: coordinator)
                .background(FeedPopGestureEnabler())
                .toolbar(.hidden, for: .navigationBar)
        case .portfolioToken(let coordinator):
            TokenDetailsCoordinatorView(coordinator: coordinator)
                .background(FeedPopGestureEnabler())
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Constants

private extension FeedDestinationView {
    enum Constants {
        static let accountFormCornerRadius: CGFloat = 24
    }
}

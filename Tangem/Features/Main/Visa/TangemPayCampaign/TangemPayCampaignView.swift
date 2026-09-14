//
//  TangemPayCampaignView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemPayCampaignView: View {
    @ObservedObject var viewModel: TangemPayCampaignViewModel

    var body: some View {
        content
            .onAppear(perform: viewModel.onAppear)
            .alert(item: $viewModel.alert) { $0.alert }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            TangemPayCampaignSkeletonView()

        case .error:
            TangemPayCampaignErrorView(onRetry: viewModel.retry, onClose: viewModel.close)

        case .landing(let landing):
            TangemPayCampaignLandingView(viewModel: viewModel, landing: landing)

        case .issueCard(let issueCard):
            TangemPayCampaignIssueCardView(viewModel: viewModel, issueCard: issueCard)
        }
    }
}

//
//  StakeDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct StakeDetailsView: View {
    @ObservedObject private var viewModel: StakeDetailsViewModel

    init(viewModel: StakeDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GroupedScrollView(alignment: .leading, spacing: 14) {
            banner

            GroupedSection(viewModel.detailsViewModels) {
                DefaultRowView(viewModel: $0)
            }
        }
    }

    private var banner: some View {
        Rectangle()
            .fill(Color.blue)
            .frame(height: 100)
    }
}

struct StakeDetailsView_Preview: PreviewProvider {
    static let viewModel = StakeDetailsViewModel(
        inputData: .init(
            tokenItem: .blockchain(
                .init(
                    .solana(
                        curve: .ed25519_slip0010,
                        testnet: false
                    ),
                    derivationPath: .none
                )
            ),
            monthEstimatedProfit: "+56.25$",
            available: 15,
            staked: 0,
            minAPR: 3.54,
            maxAPR: 5.06,
            unbonding: DateComponents(day: 3).date!,
            minimumRequirement: 0.000028,
            rewardClaimingType: .auto,
            warmupPeriod: DateComponents(day: 3).date!,
            rewardScheduleType: .block
        ),
        coordinator: StakeDetailsCoordinator()
    )

    static var previews: some View {
        StakeDetailsView(viewModel: viewModel)
    }
}

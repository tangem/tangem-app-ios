//
//  JointAccountSignaturesCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct JointAccountSignaturesCompactView: View {
    @ObservedObject var viewModel: JointAccountSignaturesCompactViewModel

    var body: some View {
        MessageBanner(
            title: Localization.jointAccountSendSignaturesRequired(viewModel.policy.signersCount, viewModel.policy.membersCount),
            description: viewModel.includesSetupFee
                ? Localization.jointAccountSendSendsAutomaticallySetupFee
                : Localization.jointAccountSendSendsAutomatically
        )
        .variant(.default)
        .glowRing(.warning)
        .slotEnd {
            DesignSystem.Icons.Document.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconStatusWarning)
        }
    }
}

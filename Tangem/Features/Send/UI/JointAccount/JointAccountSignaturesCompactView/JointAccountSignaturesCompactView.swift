//
//  JointAccountSignaturesCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct JointAccountSignaturesCompactView: View {
    @ObservedObject var viewModel: JointAccountSignaturesCompactViewModel

    var body: some View {
        MessageBanner(
            title: Localization.jointAccountSendSignaturesRequiredBanner(viewModel.policy.signersCount),
            description: viewModel.includesSetupFee
                ? Localization.jointAccountSendSendsAutomaticallySetupFee
                : Localization.jointAccountSendSendsAutomatically
        )
        .variant(.default)
        .glowRing(.warning)
    }
}

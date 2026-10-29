//
//  JointAccountAboutSignaturesView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct JointAccountAboutSignaturesView: View {
    let viewModel: JointAccountAboutSignaturesViewModel

    var body: some View {
        ModalStatus(.info, title: Localization.jointAccountInviteMembersAboutSignaturesTitle, description: viewModel.description)
            .actions(primary: gotItButton)
    }

    private var gotItButton: TangemUI.Button {
        TangemUI.Button(
            label: Localization.commonGotIt,
            accessibilityLabel: Localization.commonGotIt,
            action: viewModel.onCloseTap
        )
    }
}

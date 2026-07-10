//
//  SendAddContactFinishView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct SendAddContactFinishView: View {
    @ObservedObject var viewModel: SendAddContactFinishViewModel

    var body: some View {
        if viewModel.isVisible {
            TangemButtonV2(
                label: AttributedString(Localization.addressBookAddContact),
                iconEnd: DesignSystem.Icons.SignPlus.regular20,
                accessibilityLabel: Localization.addressBookAddContact,
                action: viewModel.userDidTapAddContact
            )
            .styleType(.secondary)
            .size(.x10)
            .horizontalLayout(.infinity)
            .padding(.top, 4)
        }
    }
}

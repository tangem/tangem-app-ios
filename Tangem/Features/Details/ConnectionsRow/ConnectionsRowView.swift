//
//  ConnectionsRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI

struct ConnectionsRowView: View {
    let viewModel: ConnectionsRowViewModel

    var body: some View {
        Row(title: viewModel.title, subtitle: viewModel.subtitle)
            .start {
                DesignSystem.Icons.GridPlus.regular20.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(DesignSystem.Color.iconBrand)
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Color.bgStatusInfoSubtle)
                    .clipShape(.rect(cornerRadius: 12))
            }
            .end(icon: DesignSystem.Icons.ChevronRight.regular20)
            .onTap(action: viewModel.action)
            .disabled(!viewModel.isEnabled)
            .accessibilityIdentifier(DetailsAccessibilityIdentifiers.connectionsButton)
    }
}

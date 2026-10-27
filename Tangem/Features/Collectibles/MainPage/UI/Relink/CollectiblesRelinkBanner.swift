//
//  CollectiblesRelinkBanner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct CollectiblesRelinkBanner: View {
    @ObservedObject var viewModel: CollectiblesRelinkBannerViewModel

    var body: some View {
        if viewModel.isVisible {
            MessageBanner(
                title: Localization.collectiblesMainRelinkTitle,
                description: Localization.collectiblesMainRelinkDescription
            )
            .variant(.error)
            .glowRing(.error)
            .slotEnd { Self.icon }
            .primaryButton(
                MessageBannerButton(
                    title: Localization.collectiblesMainRelinkButton,
                    isLoading: viewModel.isRelinking,
                    action: viewModel.relink
                )
            )
        }
    }
}

private extension CollectiblesRelinkBanner {
    // MARK: - View properties

    static var icon: some View {
        DesignSystem.Icons.Error.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .accessibilityHidden(true)
    }
}

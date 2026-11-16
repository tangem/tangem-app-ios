//
//  OnrampProviderRequirementsBottomSheetView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct OnrampProviderRequirementsBottomSheetView: View {
    @ObservedObject var viewModel: OnrampProviderRequirementsBottomSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            OnrampSheetHeaderView(
                title: Localization.onrampProviderRequirementsTitle,
                closeAction: viewModel.close
            )

            Text(Localization.onrampProviderRequirementsBody)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 24)
        }
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

// MARK: - Previews

#Preview {
    OnrampProviderRequirementsBottomSheetView(
        viewModel: OnrampProviderRequirementsBottomSheetViewModel()
    )
}

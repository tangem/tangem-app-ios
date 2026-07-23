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
import TangemUIUtils

struct OnrampProviderRequirementsBottomSheetView: View {
    @ObservedObject var viewModel: OnrampProviderRequirementsBottomSheetViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content

            NavigationBarButton.close(action: viewModel.close)
                .padding(.all, 16)
        }
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Localization.onrampProviderRequirementsTitle)
                .style(Fonts.BoldStatic.title3, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(Localization.onrampProviderRequirementsBody)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 50)
        .padding(.bottom, 24)
        .padding(.horizontal, 16)
        .infinityFrame(axis: .horizontal)
    }
}

// MARK: - Previews

#Preview {
    OnrampProviderRequirementsBottomSheetView(
        viewModel: OnrampProviderRequirementsBottomSheetViewModel()
    )
}

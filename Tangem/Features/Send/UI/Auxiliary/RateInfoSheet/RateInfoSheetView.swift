//
//  RateInfoSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct RateInfoSheetView: View {
    let viewModel: RateInfoSheetViewModel

    var body: some View {
        BottomSheetErrorContentView(
            icon: icon,
            title: title,
            subtitle: subtitle,
            closeAction: viewModel.close,
            primaryButton: MainButton.Settings(
                title: Localization.commonGotIt,
                style: .secondary,
                action: viewModel.close
            )
        )
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
        .onDisappear {
            viewModel.onDismiss()
        }
    }

    private var icon: BottomSheetErrorContentView.Icon {
        switch viewModel.rateType {
        case .fixed:
            return .init(icon: Assets.lock, overlay: Colors.Icon.accent, tint: Colors.Icon.accent)
        case .floating:
            return .init(icon: Assets.floating, overlay: Colors.Icon.accent, tint: Colors.Icon.accent)
        }
    }

    private var title: String {
        switch viewModel.rateType {
        case .fixed: Localization.sendRateFixedInfoTitle
        case .floating: Localization.sendRateFloatingInfoTitle
        }
    }

    private var subtitle: String {
        switch viewModel.rateType {
        case .fixed: Localization.sendRateFixedInfoDescription
        case .floating: Localization.sendRateFloatingInfoDescription
        }
    }
}

// MARK: - Previews

#if DEBUG
struct RateInfoSheetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RateInfoSheetView(viewModel: .init(rateType: .fixed, onDismiss: {}))
            RateInfoSheetView(viewModel: .init(rateType: .floating, onDismiss: {}))
        }
    }
}
#endif // DEBUG

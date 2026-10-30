//
//  YieldModuleClaimModal.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct YieldModuleClaimModal: View {
    @ObservedObject var viewModel: YieldModuleClaimViewModel

    @Binding var isPresented: Bool

    let onDismissed: () -> Void

    var body: some View {
        let current = appearance

        Color.clear
            .modal(
                isPresented: $isPresented,
                size: current.size,
                contentLayout: current.contentLayout,
                dragIndicator: .hidden,
                navigation: current.navigation,
                onDismiss: onDismissed,
                content: { YieldModuleClaimView(viewModel: viewModel) }
            )
            .onAppear {
                isPresented = true
            }
    }

    private var appearance: Appearance {
        switch viewModel.viewState {
        case .claim(let viewData):
            Appearance(
                size: viewData.rewardsCount > 1 ? .full : .flexible,
                contentLayout: .scrollable,
                navigation: .title(
                    Localization.yieldModuleClaimSheetTitle,
                    subtitle: Localization.yieldModuleClaimSheetSubtitle,
                    onClose: viewModel.onCloseTap
                )
            )
        case .success:
            Appearance(size: .full, contentLayout: .fill, navigation: .closeButton(onClose: viewModel.onCloseTap))
        }
    }
}

// MARK: - Appearance

private extension YieldModuleClaimModal {
    struct Appearance {
        let size: ModalSize
        let contentLayout: ModalContentLayout
        let navigation: ModalNavigation
    }
}

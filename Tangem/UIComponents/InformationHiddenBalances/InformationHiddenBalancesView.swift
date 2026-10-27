//
//  InformationHiddenBalancesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct InformationHiddenBalancesView: View {
    @ObservedObject private var viewModel: InformationHiddenBalancesViewModel

    init(viewModel: InformationHiddenBalancesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 30) {
            Assets.crossedEyeIcon.image
                .renderingMode(.template)
                .foregroundColor(DesignSystem.Color.iconPrimary)

            textView

            buttonView
        }
        .padding(.top, 46)
        .padding(.horizontal, 16)
    }

    private var textView: some View {
        VStack(spacing: 10) {
            Text(Localization.balanceHiddenTitle)
                .style(Fonts.Regular.title1, color: DesignSystem.Color.textPrimary)

            Text(Localization.balanceHiddenDescription)
                .style(Fonts.Regular.subheadline, color: DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }

    private var buttonView: some View {
        VStack(spacing: 10) {
            MainButton(title: Localization.balanceHiddenGotItButton, style: .primary) {
                viewModel.userDidRequestCloseView()
            }

            MainButton(title: Localization.balanceHiddenDoNotShowButton, style: .secondary) {
                viewModel.userDidRequestDoNotShowAgain()
            }
        }
        .padding(.vertical, 6)
    }
}

#if DEBUG
private final class BottomSheetCoordinator: ObservableObject, InformationHiddenBalancesRoutable {
    @Published var item: InformationHiddenBalancesViewModel?

    func toggleItem() {
        if item == nil {
            item = InformationHiddenBalancesViewModel(coordinator: self)
        } else {
            item = nil
        }
    }

    func hiddenBalancesSheetDidRequestClose() {
        item = nil
    }

    func hiddenBalancesSheetDidRequestDoNotShowAgain() {
        item = nil
    }
}

@available(iOS 17.0, *)
#Preview("Light") {
    @Previewable @StateObject var coordinator = BottomSheetCoordinator()

    ZStack {
        DesignSystem.Color.bgPrimary
            .edgesIgnoringSafeArea(.all)

        SwiftUI.Button("Bottom sheet isShowing \((coordinator.item != nil).description)") {
            coordinator.toggleItem()
        }
        .font(Fonts.Bold.body)
        .offset(y: -200)

        NavHolder()
            .bottomSheet(item: $coordinator.item, backgroundColor: DesignSystem.Color.bgPrimary) {
                InformationHiddenBalancesView(viewModel: $0)
            }
    }
    .preferredColorScheme(.light)
}

@available(iOS 17.0, *)
#Preview("Dark") {
    @Previewable @StateObject var coordinator = BottomSheetCoordinator()

    ZStack {
        DesignSystem.Color.bgPrimary
            .edgesIgnoringSafeArea(.all)

        SwiftUI.Button("Bottom sheet isShowing \((coordinator.item != nil).description)") {
            coordinator.toggleItem()
        }
        .font(Fonts.Bold.body)
        .offset(y: -200)

        NavHolder()
            .bottomSheet(item: $coordinator.item, backgroundColor: DesignSystem.Color.bgPrimary) {
                InformationHiddenBalancesView(viewModel: $0)
            }
    }
    .preferredColorScheme(.dark)
}
#endif // DEBUG

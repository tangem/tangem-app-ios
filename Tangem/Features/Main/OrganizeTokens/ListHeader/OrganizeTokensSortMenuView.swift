//
//  OrganizeTokensSortMenuView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct OrganizeTokensSortMenuView: View {
    @ObservedObject var viewModel: OrganizeTokensHeaderViewModel

    var body: some View {
        TangemDropDown(
            items: dropDownItems,
            label: { trigger }
        )
        .fixedSize()
    }

    private var dropDownItems: [TangemDropDownItem] {
        [
            TangemDropDownItem(
                text: Localization.organizeTokensMenuSortByBalance,
                isEnabled: !viewModel.isSortByBalanceEnabled,
                accessibilityIdentifier: OrganizeTokensAccessibilityIdentifiers.sortByBalanceButton,
                action: viewModel.toggleSortState
            ),
            TangemDropDownItem(
                text: Localization.organizeTokensMenuGroupByNetworks,
                isChecked: viewModel.isGroupingEnabled,
                accessibilityIdentifier: OrganizeTokensAccessibilityIdentifiers.groupButton,
                action: viewModel.toggleGroupState
            ),
        ]
    }

    @ViewBuilder
    private var trigger: some View {
        let icon = Assets.exchangeMini.image
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(Color.Tangem.Graphic.Neutral.primary)
            .frame(width: .unit(.x6), height: .unit(.x6))
            .accessibilityLabel("\(Localization.organizeTokensMenuSortByBalance), \(Localization.organizeTokensMenuGroupByNetworks)")

        if #available(iOS 26.0, *) {
            icon
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityIdentifier(OrganizeTokensAccessibilityIdentifiers.sortMenuTrigger)
        } else {
            icon
                .padding(.unit(.x3))
                .contentShape(.rect)
                .accessibilityIdentifier(OrganizeTokensAccessibilityIdentifiers.sortMenuTrigger)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    let optionsManager = FakeOrganizeTokensOptionsManager(
        initialGroupingOption: .none,
        initialSortingOption: .dragAndDrop
    )
    let viewModel = OrganizeTokensHeaderViewModel(
        optionsProviding: optionsManager,
        optionsEditing: optionsManager,
        analyticsLogger: TokensManagementAnalyticsLogger()
    )
    return OrganizeTokensSortMenuView(viewModel: viewModel)
        .padding()
}
#endif // DEBUG

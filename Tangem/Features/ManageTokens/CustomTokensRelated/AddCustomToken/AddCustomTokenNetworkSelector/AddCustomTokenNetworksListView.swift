//
//  AddCustomTokenNetworksListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct AddCustomTokenNetworksListView: View {
    @ObservedObject private var viewModel: AddCustomTokenNetworksListViewModel

    private let isWithPadding: Bool

    @Environment(\.isAddAndOrganizeRedesignEnabled) private var isRedesign

    init(viewModel: AddCustomTokenNetworksListViewModel, isWithPadding: Bool = true) {
        self.viewModel = viewModel
        self.isWithPadding = isWithPadding
    }

    // MARK: - Redesign-aware styling

    private var screenBackgroundColor: Color {
        isRedesign ? Color.Tangem.Surface.level2 : Colors.Background.tertiary
    }

    private var cardBackgroundColor: Color {
        isRedesign ? Color.Tangem.Surface.level3 : Colors.Background.action
    }

    private var cardCornerRadius: CGFloat {
        isRedesign ? .unit(.x5) : 14
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                ForEach(viewModel.itemViewModels, id: \.networkId) { itemViewModel in
                    AddCustomTokenNetworksListItemView(viewModel: itemViewModel)
                }
            }
            .background(cardBackgroundColor)
            .cornerRadiusContinuous(cardCornerRadius)
            .padding(.horizontal, isWithPadding ? 16 : 0)
        }
        .background(screenBackgroundColor.edgesIgnoringSafeArea(.all))
    }
}

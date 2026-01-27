//
//  ActionButtonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct ActionButtonView<ViewModel: ActionButtonViewModel>: View {
    @ObservedObject var viewModel: ViewModel

    @Environment(\.isEnabled) var isEnabled

    private var isDisabled: Bool {
        !isEnabled || viewModel.isDisabled
    }

    var body: some View {
        content
            .bindAlert($viewModel.alert)
            .frame(height: 34)
            .frame(maxWidth: .infinity)
            .background(Colors.Background.action)
            .cornerRadiusContinuous(10)
            .onTapGesture(perform: viewModel.tap)
            .disabled(isDisabled)
            .accessibilityIdentifier(viewModel.model.accessibilityIdentifier)
    }

    private var content: some View {
        HStack(spacing: 4) {
            leadingItem
                .frame(width: 20, height: 20)
            Text(viewModel.model.title)
                .style(
                    Fonts.Bold.subheadline,
                    color: isDisabled ? Colors.Text.disabled : Colors.Text.primary1
                )
        }
        .if(viewModel.viewState == .unavailable) { _ in
            EmptyView()
        }
    }

    @ViewBuilder
    private var leadingItem: some View {
        switch viewModel.viewState {
        case .initial, .idle, .restricted, .disabled:
            buttonIcon
        case .loading:
            progressView
        case .unavailable:
            EmptyView()
        }
    }

    private var buttonIcon: some View {
        viewModel.model.icon.image
            .renderingMode(.template)
            .resizable()
            .foregroundStyle(isDisabled ? Colors.Icon.inactive : Colors.Icon.primary1)
    }

    private var progressView: some View {
        ProgressView()
            .tint(Colors.Icon.informative)
            .animation(.default, value: viewModel.viewState)
    }
}

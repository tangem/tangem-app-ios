//
//  ActionButtonView.swift
//  Tangem
//
//  Created by GuitarKitty on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonView<ViewModel: ActionButtonViewModel>: View {
    @ObservedObject var viewModel: ViewModel

    private var isDisabled: Bool {
        viewModel.viewState == .disabled
    }

    var body: some View {
        Button(
            action: viewModel.tap,
            label: {
                HStack(spacing: 4) {
                    leadingItem
                        .frame(width: 20, height: 20)
                    Text(viewModel.model.title)
                        .style(
                            Fonts.Bold.subheadline,
                            color: isDisabled ? Colors.Text.disabled : Colors.Text.primary1
                        )
                }
                .bindAlert($viewModel.alert)
                .frame(height: 34)
                .frame(maxWidth: .infinity)
                .background(Colors.Background.action)
                .cornerRadiusContinuous(10)
            }
        )
    }

    @ViewBuilder
    private var leadingItem: some View {
        switch viewModel.viewState {
        case .initial, .idle, .restricted, .disabled:
            buttonIcon
        case .loading:
            progressView
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

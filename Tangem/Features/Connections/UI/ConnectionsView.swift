//
//  ConnectionsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

// [REDACTED_TODO_COMMENT]
struct ConnectionsView: View {
    @ObservedObject var viewModel: ConnectionsViewModel

    var body: some View {
        VStack {
            newConnectionButton(viewModel.state.newConnectionButton)
        }
    }

    private func newConnectionButton(_ buttonState: ConnectionsViewState.NewConnectionButton) -> some View {
        TangemUI.Button(
            label: buttonState.title,
            accessibilityLabel: nil,
            action: {
                viewModel.handle(action: .newConnectionButtonTapped)
            }
        )
        .loading(.spinner(if: buttonState.isLoading))
        .styleType(.primary)
        .size(.x12)
        .horizontalLayout(.infinity)
    }
}

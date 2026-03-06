//
//  MainPageTangemTokenRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemUIUtils

struct MainPageTangemTokenRow: View {
    @ObservedObject var viewModel: TokenItemViewModel

    init(viewModel: TokenItemViewModel) {
        self.viewModel = viewModel
    }

    private var backgroundColor: Color = .clear

    var body: some View {
        TangemTokenRow(viewData: viewModel.tokenRowViewData)
            .padding(.horizontal, .unit(.x4))
            .padding(.vertical, .unit(.x3))
            .background(backgroundColor)
            .onTapGesture(perform: viewModel.tapAction)
            .highlightable(color: .Tangem.Button.backgroundPrimary.opacity(0.03))
            // `previewContentShape` must be called just before `contextMenu` call, otherwise visual glitches may occur
            .previewContentShape(cornerRadius: .unit(.x4))
            .contextMenu {
                ForEach(viewModel.contextActionSections, id: \.self) { section in
                    Section {
                        ForEach(section.items, id: \.self) { menuAction in
                            contextMenuButton(for: menuAction)
                        }
                    }
                }
            }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuButton(for actionType: TokenActionType) -> some View {
        if actionType.isDestructive {
            Button(
                role: .destructive,
                action: { viewModel.didTapContextAction(actionType) },
                label: { labelForContextButton(with: actionType) }
            )
        } else {
            Button(
                action: { viewModel.didTapContextAction(actionType) },
                label: { labelForContextButton(with: actionType) }
            )
        }
    }

    private func labelForContextButton(with action: TokenActionType) -> some View {
        HStack {
            Text(action.title)
            action.icon.image
                .renderingMode(.template)
        }
    }
}

// MARK: - Setupable

extension MainPageTangemTokenRow: Setupable {
    func backgroundColor(_ color: Color) -> Self {
        map { $0.backgroundColor = color }
    }
}

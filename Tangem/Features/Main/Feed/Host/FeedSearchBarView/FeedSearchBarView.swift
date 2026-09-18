//
//  FeedSearchBarView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemUIUtils

struct FeedSearchBarView: View {
    @ObservedObject var viewModel: FeedSearchBarViewModel
    let isActive: Bool
    let onFocus: () -> Void
    let onCancel: () -> Void
    let onHeightChange: (CGFloat) -> Void

    @Environment(\.mainShtorkaSize) private var sheetSize

    @State private var isFocused = false

    var body: some View {
        Search(text: queryBinding, isActive: $isFocused, cancelAction: onCancel, onFocusChanged: focusDidChange)
            .placeholder(Localization.marketsSearchTitlePlaceholder)
            .onSubmit(viewModel.submit)
            .infinityFrame(axis: .horizontal)
            .padding(.horizontal, Constants.horizontalInset)
            .padding(.top, Constants.topInset)
            .readGeometry(\.size.height, onChange: { reportSearchBar(height: $0) })
            .onChange(of: isActive) { isActive in
                if !isActive {
                    isFocused = false
                }
            }
            .onChange(of: sheetSize) { size in
                if let size, size != .full {
                    isFocused = false
                }
            }
    }

    private var queryBinding: Binding<String> {
        Binding(
            get: { isActive ? viewModel.query : "" },
            set: { viewModel.query = $0 }
        )
    }

    private func focusDidChange(_ isFocused: Bool) {
        if isFocused {
            onFocus()
        }
    }

    private func reportSearchBar(height: CGFloat) {
        guard !isFocused, viewModel.query.isEmpty else {
            return
        }

        onHeightChange(height)
    }
}

// MARK: - Constants

private extension FeedSearchBarView {
    enum Constants {
        static let horizontalInset: CGFloat = 16
        static let topInset: CGFloat = 16
    }
}

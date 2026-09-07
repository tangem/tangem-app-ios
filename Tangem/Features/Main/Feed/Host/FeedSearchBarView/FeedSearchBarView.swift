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
    @ObservedObject var shtorkaStateObject: MainShtorkaStateObject

    let isActive: Bool
    let onFocus: () -> Void
    let onCancel: () -> Void

    @State private var isFocused = false

    var body: some View {
        Search(text: $viewModel.query, isActive: $isFocused, cancelAction: onCancel, onFocusChanged: focusDidChange)
            .placeholder(Localization.marketsSearchTitlePlaceholder)
            .onSubmit(viewModel.submit)
            .infinityFrame(axis: .horizontal)
            .padding(.horizontal, Constants.horizontalInset)
            .padding(.top, Constants.topInset)
            .padding(.bottom, Constants.bottomInset)
            .readGeometry(\.size.height, onChange: { reportSearchBar(height: $0) })
            .onChange(of: isActive) { isActive in
                if !isActive {
                    isFocused = false
                }
            }
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

        shtorkaStateObject.report(searchBar: height)
    }
}

// MARK: - Constants

private extension FeedSearchBarView {
    enum Constants {
        static let horizontalInset: CGFloat = 16
        static let topInset: CGFloat = 14
        static let bottomInset: CGFloat = 12
    }
}

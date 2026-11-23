//
//  ScrollableAccountPickerView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct ScrollableAccountPickerView: View {
    private let viewModel: AccountPickerViewModel
    private var bottomContentInset: CGFloat = 0

    @State private var contentBottom: CGFloat = 0
    @State private var viewportBottom: CGFloat = 0

    init(viewModel: AccountPickerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            AccountPickerView(viewModel: viewModel)
                .padding(.top, Constants.verticalPadding)
                .padding(.bottom, Constants.verticalPadding + bottomContentInset)
                .readGeometry(inCoordinateSpace: .global) { contentBottom = $0.frame.maxY }
        }
        .scrollBounceBehavior(.basedOnSize)
        .readGeometry(inCoordinateSpace: .global) { viewportBottom = $0.frame.maxY }
        .overlay(alignment: .bottom) { bottomFade }
    }

    private var hasContentBelowViewport: Bool {
        contentBottom > viewportBottom
    }

    private var bottomFade: some View {
        Fade(position: .bottom)
            .variant(.hard)
            .frame(height: Constants.fadeHeight)
            .hidden(!hasContentBelowViewport)
            .animation(.easeInOut(duration: 0.25), value: hasContentBelowViewport)
    }
}

// MARK: - Setupable

extension ScrollableAccountPickerView: Setupable {
    func bottomContentInset(_ inset: CGFloat) -> Self {
        map { $0.bottomContentInset = inset }
    }
}

// MARK: - Constants

private extension ScrollableAccountPickerView {
    enum Constants {
        static let verticalPadding: CGFloat = 16
        static let fadeHeight: CGFloat = 96
    }
}

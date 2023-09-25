//
//  ManageTokensBottomOverlayView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ManageTokensBottomOverlayView: View {
    let viewModel: ManageTokensSheetViewModel

    @State private var shouldShowSheet = false

    var body: some View {
        let bottomContainer = Color.blue.frame(height: 100.0 - 34.0) // [REDACTED_TODO_COMMENT]

        // Native sheets prevent other sheets from being presented, this approach isn't feasible at all
        if #available(iOS 9999.0, *) {
            bottomContainer
                .sheet(isPresented: $shouldShowSheet) {
                    VStack(spacing: 0.0) {
                        Spacer(minLength: 40.0) // [REDACTED_TODO_COMMENT]

                        _ManageTokensHeaderView(viewModel: viewModel)

                        ScrollView(.vertical, showsIndicators: true) { _ManageTokensView(viewModel: viewModel) }
                    }
                    .configureSheetPresentationController { controller in
                        let identifier = UISheetPresentationController.Detent.Identifier("com.tangem.ManageTokensLargestUndimmedDetent")
                        let constant = 100.0 - 34.0 // 34 is the safeAreaInsets.bottom, get it properly!
                        let largestUndimmedDetent: UISheetPresentationController.Detent

                        if #available(iOS 16.0, *) {
                            largestUndimmedDetent = .custom(identifier: identifier) { _ in constant }
                        } else {
                            largestUndimmedDetent = UISheetPresentationController.Detent.perform(
                                Selector("X2RldGVudFdpdGhJZGVudGlmaWVyOmNvbnN0YW50Og==".base64Decoded()!),
                                with: identifier,
                                with: constant
                            ).takeUnretainedValue() as! UISheetPresentationController.Detent
                        }

                        controller.largestUndimmedDetentIdentifier = identifier
                        controller.detents = [
                            largestUndimmedDetent,
                            .large(),
                        ]
                        controller.preferredCornerRadius = 24.0
                        controller.prefersGrabberVisible = true
                    }
                    .interactiveDismissDisabledCompat()
                }
                .task { @MainActor in
                    // [REDACTED_TODO_COMMENT]
                    try! await Task.sleep(seconds: 0.5)
                    shouldShowSheet = true
                }
        } else {
            bottomContainer
                .bottomScrollableSheet(
                    header: {
                        _ManageTokensHeaderView(viewModel: viewModel)
                    },
                    content: {
                        _ManageTokensView(viewModel: viewModel)
                    }
                )
        }
    }
}

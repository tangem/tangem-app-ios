//
//  StepsFlowBar.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct StepsFlowBar: View {
    let title: String?
    let leadingItem: StepsFlowNavBarItem?
    let trailingItem: StepsFlowNavBarItem?
    let progressBarValue: Double
    let configuration: StepsFlowConfiguration

    var body: some View {
        VStack(spacing: 4) {
            navBar

            if configuration.hasProgressBar {
                makeProgressBar(value: progressBarValue)
                    .padding(.horizontal, configuration.progressBarPadding)
            }
        }
    }
}

// MARK: - Subviews

private extension StepsFlowBar {
    var navBar: some View {
        NavigationBar(
            title: title ?? .empty,
            settings: NavigationBar.Settings(
                backgroundColor: .clear,
                height: configuration.navigationBarHeight
            ),
            leftButtons: navBarLeadingItemView,
            rightButtons: navBarTrailingItemView
        )
    }

    func makeProgressBar(value: Double) -> some View {
        ProgressBar(
            height: configuration.progressBarHeight,
            currentProgress: value
        )
    }

    func navBarLeadingItemView() -> some View {
        leadingItem.map { $0.content() }
    }

    func navBarTrailingItemView() -> some View {
        trailingItem.map { $0.content() }
    }
}

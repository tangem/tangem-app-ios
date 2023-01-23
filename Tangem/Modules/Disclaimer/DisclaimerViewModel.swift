//
//  DisclaimerViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class DisclaimerViewModel: Identifiable {
    let webViewModel: WebViewContainerViewModel
    let bottomOverlayHeight: CGFloat = 170
    let id: UUID = .init()

    var showBottomOverlay: Bool { style == .onboarding }

    private let style: DisclaimerView.Style

    init(
        url: URL,
        style: DisclaimerView.Style
    ) {
        self.style = style
        webViewModel = .init(
            url: url,
            title: "",
            addLoadingIndicator: true,
            withCloseButton: false,
            withNavigationBar: false,
            contentInset: .init(top: 0, left: 0, bottom: bottomOverlayHeight / 2, right: 0)
        )
    }
}

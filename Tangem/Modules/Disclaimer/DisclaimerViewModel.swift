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
    let id: UUID = .init()

    var showNavBarTitle: Bool { style == .details }
    var bottomOverlayHeight: CGFloat { style.bottomOverlayHeight }

    private let style: Style

    init(
        url: URL,
        style: Style
    ) {
        self.style = style
        webViewModel = .init(
            url: url,
            title: "",
            addLoadingIndicator: true,
            withCloseButton: false,
            withNavigationBar: false,
            contentInset: .init(top: 0, left: 0, bottom: style.bottomOverlayHeight / 2, right: 0)
        )
    }
}

extension DisclaimerViewModel {
    enum Style {
        case onboarding
        case details

        var bottomOverlayHeight: CGFloat {
            switch self {
            case .details:
                return 40
            case .onboarding:
                return 170
            }
        }
    }
}

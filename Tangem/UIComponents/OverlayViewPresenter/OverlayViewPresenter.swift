//
//  OverlayViewPresenter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

@MainActor
protocol OverlayViewPresenter: AnyObject {
    func present(_ view: OverlayView)
    func dismiss()
}

struct OverlayView: Identifiable {
    let id: String
    let view: AnyView
    let style: PresentationStyle
    let animated: Bool

    init(id: String = UUID().uuidString, view: AnyView, style: PresentationStyle, animated: Bool = true) {
        self.id = id
        self.view = view
        self.style = style
        self.animated = animated
    }

    enum PresentationStyle {
        case sheet
        case fullScreenCover
    }
}

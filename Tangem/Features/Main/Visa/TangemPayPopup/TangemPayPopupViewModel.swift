//
//  TangemPayPopupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI
import SwiftUI

@MainActor
protocol TangemPayPopupViewModel: AnyObject, FloatingSheetContentViewModel {
    var title: AttributedString { get }
    var description: AttributedString { get }
    var icon: Image { get }
    var primaryButton: MainButton.Settings { get }
    var secondaryButton: MainButton.Settings? { get }
    var primaryButtonAccessibilityIdentifier: String? { get }

    func onHyperLinkTap(_ link: URL)
    func dismiss()
}

extension TangemPayPopupViewModel {
    var secondaryButton: MainButton.Settings? { nil }
    var primaryButtonAccessibilityIdentifier: String? { nil }
    func onHyperLinkTap(_ link: URL) {}
}

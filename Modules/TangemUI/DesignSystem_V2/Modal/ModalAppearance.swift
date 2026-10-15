//
//  ModalAppearance.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit

public enum ModalAppearance {
    public static var cornerRadius: CGFloat? {
        if #available(iOS 26.0, *) {
            nil
        } else {
            36
        }
    }

    public static func applyFull(to sheet: UISheetPresentationController) {
        sheet.detents = [.large()]
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = cornerRadius
    }
}

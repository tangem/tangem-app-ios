//
//  JointAccountCopyHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit
import TangemAssets
import TangemFoundation
import TangemUI

struct JointAccountCopyHelper {
    func copy(_ value: String, toast text: String) {
        UIPasteboard.general.string = value
        FeedbackGenerator.selectionChanged()

        LegacyToast(
            view: TangemSnackbar(title: text)
                .icon(DesignSystem.Icons.Checkmark.regular20)
                .iconColor(DesignSystem.Color.iconAccentBlue)
        )
        .present(layout: .top(padding: 14), type: .temporary())
    }
}

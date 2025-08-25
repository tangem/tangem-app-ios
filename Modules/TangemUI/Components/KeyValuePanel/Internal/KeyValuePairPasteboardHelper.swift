//
//  KeyValuePairPasteboardHelper.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemLocalization

struct KeyValuePairPasteboardHelper {
    func copyToPasteboard(_ viewData: KeyValuePairViewData) {
        UIPasteboard.general.string = viewData.value.text

        let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        heavyImpactGenerator.impactOccurred()

        Toast(view: SuccessToast(text: Localization.commonValueCopied))
            .present(
                layout: .top(padding: 20.0),
                type: .temporary()
            )
    }
}

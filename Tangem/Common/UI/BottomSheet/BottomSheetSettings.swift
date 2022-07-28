//
//  BottomSheetSettings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit

struct BottomSheetSettings: Identifiable {
    var id: UUID = UUID()
    var showClosedButton: Bool = true
    var swipeDownToDismissEnabled: Bool = true
    var tapOutsideToDismissEnabled: Bool = true
    var cornerRadius: CGFloat = 10
    var backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.7)
    var backgroundAlpha: CGFloat = 0.3
    var bottomBackgroundSheetColor: UIColor = UIColor.white
}

extension BottomSheetSettings {
    static var `default`: BottomSheetSettings {
        BottomSheetSettings()
    }

    static var qr: BottomSheetSettings {
        BottomSheetSettings()
    }

    static var warning: BottomSheetSettings {
        BottomSheetSettings(showClosedButton: false)
    }
}

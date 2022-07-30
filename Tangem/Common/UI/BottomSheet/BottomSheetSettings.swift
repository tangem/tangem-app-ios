//
//  BottomSheetSettings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI

struct BottomSheetSettings: Identifiable {
    var id: UUID = UUID()
    var showClosedButton: Bool = true
    var swipeDownToDismissEnabled: Bool = true
    var tapOutsideToDismissEnabled: Bool = true
    var cornerRadius: CGFloat = 10
    var backgroundColor: Color = Colors.Background.action.opacity(0.7)
    var backgroundSheetColor: Color = Color.white
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

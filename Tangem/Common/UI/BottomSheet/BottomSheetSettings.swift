//
//  BottomSheetSettings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit

class BottomSheetSettings: Identifiable {
    var id: UUID = UUID()
    var showClosedButton: Bool { true }
    var swipeDownToDismissEnabled: Bool { true }
    var tapOutsideToDismissEnabled: Bool { true }
    var cornerRadius: CGFloat { 10 }
    var backgroundColor: UIColor { UIColor.black.withAlphaComponent(0.7) }
    var bottomSheetSize: BottomSheetBaseController.PreferredSheetSizing { .adaptive }
    var impactOnShow: ImpactFeedback { .none }
}

extension BottomSheetSettings {
    static func QR() -> BottomSheetSettings {
        QRBottomSheetSettings()
    }

    static func Warning() -> BottomSheetSettings {
        WarningBottomSheetSettings()
    }
}

class QRBottomSheetSettings: BottomSheetSettings { }

class WarningBottomSheetSettings: BottomSheetSettings {
    override var cornerRadius: CGFloat { 30 }
    override var showClosedButton: Bool { false }
//    override var impactOnShow: ImpactFeedback { .warning }
}

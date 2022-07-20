//
//  BottomSheetSettings.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 12.07.2022.
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
}

extension BottomSheetSettings {
    static func `default`() -> BottomSheetSettings {
        BottomSheetSettings()
    }

    static func qr() -> BottomSheetSettings {
        BottomSheetSettings()
    }

    static func warning() -> BottomSheetSettings {
        BottomSheetSettings(showClosedButton: false)
    }
}

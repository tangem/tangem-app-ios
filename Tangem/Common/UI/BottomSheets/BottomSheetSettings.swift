//
//  BottomSheetSettings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit

protocol BottomSheetSettings {
    var showClosedButton: Bool { get }
    var addDragGesture: Bool { get }
    var closeOnTapOutside: Bool { get }
    var cornerRadius: CGFloat { get }
}

enum BottomSheet: BottomSheetSettings {
    case qr
    case warning

    var cornerRadius: CGFloat {
        switch self {
        case .qr:
            return 10
        case .warning:
            return 30
        }
    }

    var showClosedButton: Bool {
        switch self {
        case .qr:
            return true
        case .warning:
            return false
        }
    }

    var addDragGesture: Bool {
        true
    }

    var closeOnTapOutside: Bool {
        true
    }
}

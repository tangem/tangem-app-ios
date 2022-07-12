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

//
//  QRScanViewRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol QRScanViewRoutable {
    func present(_ actionSheet: ActionSheetBinder)
    func openImagePicker()
    func openSettings()
    func dismiss()
}

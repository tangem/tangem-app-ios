//
//  AlertPresenter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUIUtils.AlertBinder
import struct TangemUIUtils.ActionSheetBinder

protocol AlertPresenter: AnyObject {
    func present(alert: AlertBinder)
    func present(actionSheet: ActionSheetBinder)

    func hideAlert()
}

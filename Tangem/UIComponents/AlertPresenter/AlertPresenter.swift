//
//  AlertPresenter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUIUtils.AlertBinder

protocol AlertPresenter: AnyObject {
    func present(alert: AlertBinder)
}

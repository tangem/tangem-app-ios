//
//  AppSettingsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol AppSettingsRoutable: AnyObject {
    func openTokenSynchronization()
    func openResetSavedCards()
    func openAppSettings()
    func openCurrencySelection()
    func openThemeSelection()
}

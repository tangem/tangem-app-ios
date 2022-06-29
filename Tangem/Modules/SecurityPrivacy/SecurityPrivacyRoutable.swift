//
//  SecurityPrivacyRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol SecurityPrivacyRoutable: AnyObject {
    func didRequestChangePassword()
    func didRequestSecurityManagement(cardModel: CardViewModel)
    func didRequestTokenSynchronization()
    func didRequestResetSavedCards()
}

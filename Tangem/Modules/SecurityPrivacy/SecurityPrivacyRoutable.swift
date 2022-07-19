//
//  SecurityPrivacyRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol SecurityPrivacyRoutable: AnyObject {
    func openChangeAccessCode()
    func openSecurityMode(cardModel: CardViewModel)
    func openTokenSynchronization()
    func openResetSavedCards()
}

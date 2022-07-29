//
//  CardSettingsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol CardSettingsRoutable: AnyObject {
    func openChangeAccessCodeWarningView(action: @escaping (@escaping (Result<Void, Error>) -> Void) -> Void)
    func openSecurityMode(cardModel: CardViewModel)
}

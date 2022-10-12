//
//  TokenListRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenListRoutable: AnyObject {
    func closeModule()
    func openAddCustom(for cardModel: CardViewModel)
}

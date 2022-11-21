//
//  ReferralRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol ReferralRoutable: AnyObject {
    func openTos(with url: URL)
    func dismiss()
}

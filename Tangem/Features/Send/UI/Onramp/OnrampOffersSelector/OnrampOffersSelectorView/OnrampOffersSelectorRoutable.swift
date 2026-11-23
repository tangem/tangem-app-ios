//
//  OnrampOffersSelectorRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol OnrampOffersSelectorRoutable: AnyObject {
    func closeOnrampOffersSelector(then action: (() -> Void)?)
}

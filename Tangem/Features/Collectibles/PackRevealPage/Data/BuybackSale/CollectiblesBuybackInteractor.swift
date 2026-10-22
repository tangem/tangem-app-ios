//
//  CollectiblesBuybackInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol CollectiblesBuybackInteractor {
    func sell(nftAddress: String, offer: CollectiblesBuybackOffer) async throws
}

enum CollectiblesBuybackSaleError: Error {
    case accountNotReady
    case failed
    case notConfirmed
}

//
//  TokenItemPromoProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol TokenItemPromoProvider {
    func makePromoOutputPublisher(
        using promoInputPublisher: some Publisher<[TokenItemPromoProviderInput], Never>
    ) -> AnyPublisher<TokenItemPromoProviderOutput?, Never>

    func hidePromoBubble()
}

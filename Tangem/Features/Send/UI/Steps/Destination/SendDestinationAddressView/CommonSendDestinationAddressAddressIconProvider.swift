//
//  CommonSendDestinationAddressAddressIconProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

final class CommonSendDestinationAddressAddressIconProvider {
    private var tokenItem: TokenItem?
    private var tokenItemSubscription: AnyCancellable?

    init(tokenItemPublisher: some Publisher<TokenItem, Never>) {
        tokenItemSubscription = tokenItemPublisher
            .eraseToOptional()
            .receiveOnMain()
            .assign(to: \.tokenItem, on: self, ownership: .weak)
    }
}

// MARK: - SendDestinationAddressAddressIconProvider

extension CommonSendDestinationAddressAddressIconProvider: SendDestinationAddressAddressIconProvider {
    func makeIcon(for address: String) -> AddressIconProviderViewType? {
        AddressIconProvider.makeViewType(
            address: address,
            networkId: tokenItem.map { AddressBookNetworkID($0.blockchain.networkId) }
        )
    }
}

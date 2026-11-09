//
//  BlockiesSendDestinationAddressAddressIconProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct BlockiesSendDestinationAddressAddressIconProvider: SendDestinationAddressAddressIconProvider {
    func makeIcon(for address: String) -> AddressIconProviderViewType? {
        .blockies(AddressIconProvider.makeBlockiesIconViewData(address: address))
    }
}

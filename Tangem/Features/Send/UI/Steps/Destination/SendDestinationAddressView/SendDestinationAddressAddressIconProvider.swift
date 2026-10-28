//
//  SendDestinationAddressAddressIconProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SendDestinationAddressAddressIconProvider {
    func makeIcon(for address: String) -> AddressIconProviderViewType?
}

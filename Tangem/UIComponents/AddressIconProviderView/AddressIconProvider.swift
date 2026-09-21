//
//  AddressIconProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockiesSwift
import class UIKit.UIImage

enum AddressIconProvider {
    static func makeViewType(address: String, networkId: AddressBookNetworkID?) -> AddressIconProviderViewType? {
        if let contactNameIconData = makeAddressBookContactNameIconData(address: address, networkId: networkId) {
            return .contact(contactNameIconData)
        }

        if let blockiesImage = makeBlockiesImage(address: address) {
            return .blockies(AddressBlockiesIconViewData(image: blockiesImage))
        }

        return .none
    }

    static func makeBlockiesIconViewData(address: String) -> AddressBlockiesIconViewData {
        AddressBlockiesIconViewData(image: makeBlockiesImage(address: address))
    }

    static func makeBlockiesImage(address: String) -> UIImage? {
        guard !address.isEmpty else {
            return nil
        }

        let blockies = Blockies(
            seed: address.lowercased(),
            size: Constants.numberOfBlocks,
            scale: Constants.scale
        )

        return blockies.createImage()
    }

    static func makeAddressBookContactNameIconData(
        address: String,
        networkId: AddressBookNetworkID?
    ) -> AddressBookContactNameIconViewData? {
        guard !address.isEmpty else {
            return nil
        }

        let userWalletRepository: UserWalletRepository = InjectedValues[\.userWalletRepository]
        let finder = AddressBookContactFinder(
            contacts: userWalletRepository.models.flatMap { $0.addressBookManager.contacts },
            walletId: userWalletRepository.selectedModel?.userWalletId
        )

        return finder
            .contact(address: address, networkId: networkId)
            .map(AddressBookContactNameIconViewData.init(contact:))
    }
}

extension AddressIconProvider {
    private enum Constants {
        static let numberOfBlocks = 12
        static let scale = 3
    }
}

enum AddressIconProviderViewType: Equatable {
    case contact(AddressBookContactNameIconViewData)
    case blockies(AddressBlockiesIconViewData)
}

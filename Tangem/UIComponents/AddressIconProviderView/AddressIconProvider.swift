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
    static func makeViewType(address: String) -> AddressIconProviderViewType? {
        if let contactNameIconData = makeAddressBookContactNameIconData(address: address) {
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

    static func makeAddressBookContactNameIconData(address: String) -> AddressBookContactNameIconViewData? {
        guard FeatureProvider.isAvailable(.addressBook) else {
            return nil
        }

        guard !address.isEmpty else {
            return nil
        }

        let userWalletRepository: UserWalletRepository = InjectedValues[\.userWalletRepository]
        let contacts = userWalletRepository.models.flatMap { $0.addressBookManager.contacts }

        guard let contact = contacts.first(where: { $0.entries.caseInsensitiveContains(address: address) }) else {
            return nil
        }

        return AddressBookContactNameIconViewData(contact: contact)
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

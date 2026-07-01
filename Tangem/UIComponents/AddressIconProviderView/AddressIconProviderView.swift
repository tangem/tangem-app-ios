//
//  AddressIconProviderView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddressIconProviderView: View {
    let type: AddressIconProviderViewType?
    let size: CGFloat

    init(type: AddressIconProviderViewType?, size: CGFloat = 40) {
        self.type = type
        self.size = size
    }

    var body: some View {
        switch type {
        case .contact(let viewData):
            AddressBookContactNameIconView(viewData: viewData, size: size)
        case .blockies(let viewData):
            AddressBlockiesIconView(viewData: viewData, size: size)
        case .none:
            AddressIconPlaceholderView(size: size)
        }
    }
}

struct AddressIconViewModel {
    let addressIconType: AddressIconProviderViewType?

    init(address: String) {
        addressIconType = AddressIconProvider.makeViewType(address: address)
    }
}

struct AddressIconView: View {
    let viewModel: AddressIconViewModel

    var body: some View {
        AddressIconProviderView(type: viewModel.addressIconType)
    }
}

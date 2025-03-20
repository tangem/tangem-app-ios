//
//  AddressIconView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddressIconView: View {
    let viewModel: AddressIconViewModel

    var body: some View {
        image
            .clipShape(Circle())
            .frame(width: viewModel.size, height: viewModel.size)
    }

    @ViewBuilder
    private var image: some View {
        if let image = viewModel.image {
            Image(uiImage: image)
        } else {
            Colors.Button.secondary
        }
    }
}

struct AddressIconView_Previews: PreviewProvider {
    static var previews: some View {
        AddressIconView(viewModel: AddressIconViewModel(address: "0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359"))
    }
}

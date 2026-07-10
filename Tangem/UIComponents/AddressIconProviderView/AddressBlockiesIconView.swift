//
//  AddressBlockiesIconView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct AddressBlockiesIconViewData: Equatable {
    let image: UIImage?
}

struct AddressBlockiesIconView: View {
    let viewData: AddressBlockiesIconViewData
    @ScaledMetric private var size: CGFloat

    init(viewData: AddressBlockiesIconViewData, size: CGFloat = 40) {
        self.viewData = viewData
        _size = ScaledMetric(wrappedValue: size)
    }

    var body: some View {
        content
            .frame(width: size, height: size)
            .clipShape(Circle())
    }

    @ViewBuilder
    private var content: some View {
        if let image = viewData.image {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
        } else {
            DesignSystem.Color.bgOpaquePrimary
        }
    }
}

struct AddressIconPlaceholderView: View {
    @ScaledMetric private var size: CGFloat

    init(size: CGFloat = 40) {
        _size = ScaledMetric(wrappedValue: size)
    }

    var body: some View {
        Circle()
            .fill(DesignSystem.Color.bgOpaquePrimary)
            .frame(width: size, height: size)
    }
}

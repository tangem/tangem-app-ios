//
//  TangemPayReceiveAddressTypesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

struct TangemPayReceiveAddressTypesProvider {
    let address: String
    let colorScheme: ReceiveAddressInfoUtils.ColorScheme

    private var receiveAddressInfo: ReceiveAddressInfo {
        .init(
            address: address,
            type: .default,
            localizedName: "",
            addressQRImage: QrCodeGenerator.generateQRCode(
                from: address,
                backgroundColor: colorScheme.backgroundColor,
                foregroundColor: colorScheme.foregroundColor
            )
        )
    }
}

extension TangemPayReceiveAddressTypesProvider: ReceiveAddressTypesProvider {
    var receiveAddressTypesPublisher: AnyPublisher<[ReceiveAddressType], Never> {
        .just(output: [.address(receiveAddressInfo)])
    }
}

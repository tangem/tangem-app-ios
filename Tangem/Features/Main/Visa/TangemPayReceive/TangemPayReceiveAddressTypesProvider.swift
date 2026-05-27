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
        ReceiveAddressInfo(
            address: address,
            type: .default,
            localizedName: "",
            qrBackgroundColor: colorScheme.backgroundColor,
            qrForegroundColor: colorScheme.foregroundColor
        )
    }
}

// MARK: ReceiveAddressTypesProvider

extension TangemPayReceiveAddressTypesProvider: ReceiveAddressTypesProvider {
    var receiveAddressTypesPublisher: AnyPublisher<[ReceiveAddressType], Never> {
        .just(output: [.address(receiveAddressInfo)])
    }
}

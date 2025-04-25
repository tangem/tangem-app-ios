//
//  ReceiveBottomSheetUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct ReceiveBottomSheetUtils {
    let flow: ReceiveBottomSheetViewModel.Flow

    func makeAddressInfos(from addresses: [Address]) -> [ReceiveAddressInfo] {
        return addresses.map { address in
            ReceiveAddressInfo(
                address: address.value,
                type: address.type,
                localizedName: address.localizedName,
                addressQRImage: QrCodeGenerator.generateQRCode(from: address.value)
            )
        }
    }

    func makeViewModel(for walletModel: any WalletModel) -> ReceiveBottomSheetViewModel {
        let addressInfos = makeAddressInfos(from: walletModel.addresses)

        return ReceiveBottomSheetViewModel(
            flow: flow,
            tokenItem: walletModel.tokenItem,
            addressInfos: addressInfos
        )
    }
}

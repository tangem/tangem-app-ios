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

    func makeViewModel(for tokenItem: TokenItem, addressInfos: [ReceiveAddressInfo]) -> ReceiveBottomSheetViewModel {
        let notificationInputsFactory = ReceiveBottomSheetNotificationInputsFactory(flow: flow)
        let notificationInputs = notificationInputsFactory.makeNotificationInputs(for: tokenItem)

        return ReceiveBottomSheetViewModel(
            flow: flow,
            tokenItem: tokenItem,
            notificationInputs: notificationInputs,
            addressInfos: addressInfos
        )
    }
}

// MARK: - Convenience extensions

extension ReceiveBottomSheetUtils {
    func makeViewModel(for walletModel: any WalletModel) -> ReceiveBottomSheetViewModel {
        let addressInfos = makeAddressInfos(from: walletModel.addresses)

        return makeViewModel(for: walletModel.tokenItem, addressInfos: addressInfos)
    }
}

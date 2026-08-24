//
//  TangemPayNetworkRow.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemPay

struct TangemPayNetworkRow: Identifiable, Equatable {
    let id: Int
    let title: String
    let subtitle: String
    let icon: ImageType
    let status: TangemPayBalance.Network.Status
    let action: Action?

    enum Action: Equatable {
        case receive(TangemPayReceiveSheetViewModel.Input)
        case issueContract(chainId: Int)
        case explainOtherNetworks
    }
}

//
//  PolymarketChooseNetworkSheetRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol PolymarketChooseNetworkSheetRoutable: AnyObject {
    func chooseNetworkSheetRequestReceive(input: PolymarketReceiveSheetViewModel.Input)

    func closeChooseNetworkSheet()
}

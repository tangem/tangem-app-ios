//
//  TangemPayChooseNetworkSheetRoutable.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol TangemPayChooseNetworkSheetRoutable: AnyObject {
    func chooseNetworkSheetRequestReceive(input: TangemPayReceiveSheetViewModel.Input)
    func chooseNetworkSheetRequestOtherNetworks()
    func closeChooseNetworkSheet()
}

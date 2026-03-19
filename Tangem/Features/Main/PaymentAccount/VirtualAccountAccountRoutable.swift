//
//  VirtualAccountAccountRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol VirtualAccountAccountRoutable: AnyObject {
    func openVirtualAccountProvisioningPopup()
    func openVirtualAccountFailedToProvisionPopup()
    func openVirtualAccountKYCInProgressPopup(paymentAccountKYCInteractor: PaymentAccountKYCInteractor)
    func openVirtualAccountKYCDeclinedPopup(paymentAccountKYCInteractor: PaymentAccountKYCInteractor)
    func openVirtualAccountMainView(activeState: VirtualAccountActiveState)
}

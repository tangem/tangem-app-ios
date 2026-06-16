//
//  AddressBookAddAddressViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class AddressBookAddAddressViewModel: ObservableObject, Identifiable {
    let destinationAddressViewModel: SendDestinationAddressViewModel
    let additionalFieldViewModel: SendDestinationAdditionalFieldViewModel

    private weak var coordinator: AddressBookAddAddressRoutable?

    init(coordinator: AddressBookAddAddressRoutable) {
        self.coordinator = coordinator

        destinationAddressViewModel = SendDestinationAddressViewModel(
            textViewModel: .init(),
            address: .init(string: "", source: .textField)
        )

        additionalFieldViewModel = SendDestinationAdditionalFieldViewModel(title: Localization.sendExtrasHintMemo)

        destinationAddressViewModel.router = self
    }

    func userDidRequestDismiss() {
        coordinator?.dismissAddAddress()
    }
}

// MARK: - SendDestinationAddressViewRoutable

extension AddressBookAddAddressViewModel: SendDestinationAddressViewRoutable {
    func didTapScanQRButton() {
        coordinator?.openQRScanner(output: self)
    }
}

// MARK: - QRScannerOutput

extension AddressBookAddAddressViewModel: QRScannerOutput {
    func qrScanDidScan(string: String) {
        destinationAddressViewModel.update(address: .init(string: string, source: .qrCode))
    }
}

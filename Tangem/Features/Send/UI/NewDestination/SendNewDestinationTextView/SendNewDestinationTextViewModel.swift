//
//  SendNewDestinationAddressViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol SendNewDestinationAddressViewRoutable: AnyObject {
    func didTapScanQRButton()
}

class SendNewDestinationAddressViewModel: ObservableObject, Identifiable {
    @Published private(set) var textViewModel: SUITextViewModel
    @Published private(set) var address: Address
    @Published private(set) var error: String?
    @Published private(set) var isValidating: Bool = false

    var text: BindingValue<String> {
        .init(
            root: self, default: "",
            get: { $0.address.string },
            set: { $0.address = .init(string: $1, source: .textField) }
        )
    }

    weak var router: SendNewDestinationAddressViewRoutable?

    init(textViewModel: SUITextViewModel, address: Address) {
        self.textViewModel = textViewModel
        self.address = address
    }

    func addressPublisher() -> AnyPublisher<Address, Never> {
        $address.eraseToAnyPublisher()
    }

    func update(error: String?) {
        self.error = error
    }

    func update(address: Address) {
        self.address = address
    }

    func update(isValidating: Bool) {
        self.isValidating = isValidating
    }

    func didTapPasteButton(string: String) {
        FeedbackGenerator.success()
        address = .init(string: string, source: .pasteButton)
    }

    func didTapClearButton() {
        address = .init(string: "", source: .textField)
    }

    func didTapScanQRButton() {
        router?.didTapScanQRButton()
    }
}

extension SendNewDestinationAddressViewModel {
    enum TitleType {
        case title
        case error(String)
    }

    struct Address {
        let string: String
        let source: Analytics.DestinationAddressSource
    }
}

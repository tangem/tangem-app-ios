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
    @Published private(set) var sendAddress: SendAddress
    @Published private(set) var error: String?
    @Published private(set) var isValidating: Bool = false

    var text: BindingValue<String> {
        .init(
            root: self, default: "",
            get: { $0.sendAddress.value },
            set: { $0.sendAddress = .init(value: $1, source: .textField) }
        )
    }

    private weak var router: SendNewDestinationAddressViewRoutable?

    init(textViewModel: SUITextViewModel, sendAddress: SendAddress, router: SendNewDestinationAddressViewRoutable) {
        self.textViewModel = textViewModel
        self.sendAddress = sendAddress
        self.router = router
    }

    func addressPublisher() -> AnyPublisher<SendAddress, Never> {
        $sendAddress.eraseToAnyPublisher()
    }

    func update(error: String?) {
        self.error = error
    }

    func update(address: SendAddress) {
        sendAddress = address
    }

    func update(isValidating: Bool) {
        self.isValidating = isValidating
    }

    func didTapPasteButton(string: String) {
        FeedbackGenerator.success()
        sendAddress = .init(value: string, source: .pasteButton)
    }

    func didTapClearButton() {
        sendAddress = .init(value: "", source: .textField)
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
}

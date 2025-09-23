//
//  SendDestinationAdditionalFieldViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization

class SendDestinationAdditionalFieldViewModel: ObservableObject, Identifiable {
    @Published var title: String
    @Published var text: String = ""
    @Published var error: String?
    @Published var disabled: Bool = false

    var placeholder: String {
        disabled ? Localization.sendAdditionalFieldAlreadyIncluded : Localization.sendOptionalField
    }

    init(title: String, text: String = "") {
        self.title = title
        self.text = text
    }

    func textPublisher() -> AnyPublisher<String, Never> {
        $text.eraseToAnyPublisher()
    }

    func update(text: String) {
        self.text = text
    }

    func update(error: String?) {
        self.error = error
    }

    func update(disabled: Bool) {
        self.disabled = disabled
    }

    func didTapPasteButton(string: String) {
        FeedbackGenerator.success()
        text = string
    }

    func didTapClearButton() {
        text = ""
    }
}

extension SendDestinationAdditionalFieldViewModel {
    enum TitleType {
        case title(name: String)
        case error(String)
    }
}

//
//  SendDestinationInputViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SendDestinationInputViewModel: ObservableObject, Identifiable {
    let name: String
    let showAddressIcon: Bool
    let placeholder: String
    let description: String
    let didEnterDestination: (String) -> Void

    @Published var input: String = ""
    @Published var errorText: String?

    var hasTextInClipboard = false

    private var bag: Set<AnyCancellable> = []

    init(
        name: String,
        input: AnyPublisher<String, Never>,
        showAddressIcon: Bool,
        placeholder: String,
        description: String,
        errorText: AnyPublisher<Error?, Never>,
        didEnterDestination: @escaping (String) -> Void
    ) {
        self.name = name
        self.showAddressIcon = showAddressIcon
        self.placeholder = placeholder
        self.description = description
        self.didEnterDestination = didEnterDestination

        bind(input: input, errorText: errorText)
    }

    private func bind(input: AnyPublisher<String, Never>, errorText: AnyPublisher<Error?, Never>) {
        input
            .assign(to: \.input, on: self, ownership: .weak)
            .store(in: &bag)

        self.$input
            .removeDuplicates()
            .sink { [weak self] in
                self?.didEnterDestination($0)
            }
            .store(in: &bag)

        errorText
            .map {
                $0?.localizedDescription
            }
            .assign(to: \.errorText, on: self, ownership: .weak)
            .store(in: &bag)

        if #unavailable(iOS 16.0) {
            NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)
                .sink { [weak self] _ in
                    self?.updatePasteButton()
                }
                .store(in: &bag)

            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.onBecomingActive()
                }
                .store(in: &bag)

            updatePasteButton()
        }
    }

    func onAppear() {
        updatePasteButton()
    }

    func onBecomingActive() {
        updatePasteButton()
    }

    func didTapLegacyPasteButton() {
        guard let input = UIPasteboard.general.string else {
            return
        }

        didEnterDestination(input)
    }

    func clearInput() {
        didEnterDestination("")
    }

    private func updatePasteButton() {
        if #unavailable(iOS 16.0) {
            hasTextInClipboard = UIPasteboard.general.hasStrings
        }
    }
}

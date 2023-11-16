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

class SendDestinationInputViewModel: Identifiable {
    let name: String
    let showAddressIcon: Bool
    let placeholder: String
    let description: String
    let didPasteAddress: ([String]) -> Void

    var input: Binding<String>
    var hasTextInClipboard = false
    var errorText: String?

    private var bag: Set<AnyCancellable> = []

    init(
        name: String,
        input: Binding<String>,
        showAddressIcon: Bool,
        placeholder: String,
        description: String,
        didPasteAddress: @escaping ([String]) -> Void
    ) {
        self.name = name
        self.input = input
        self.showAddressIcon = showAddressIcon
        self.placeholder = placeholder
        self.description = description
        self.didPasteAddress = didPasteAddress

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

        didPasteAddress([input])
    }

    func clearInput() {
        input.wrappedValue = ""
    }

    private func updatePasteButton() {
        if #unavailable(iOS 16.0) {
            hasTextInClipboard = UIPasteboard.general.hasStrings
        }
    }
}

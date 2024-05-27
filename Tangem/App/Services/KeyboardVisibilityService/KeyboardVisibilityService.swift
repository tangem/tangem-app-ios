//
//  KeyboardVisibilityService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import UIKit
import Combine

class KeyboardVisibilityService {
    private(set) var keyboardVisible = false

    private var visibilitySubscription: AnyCancellable?
    private var hideKeyboardSubscription: AnyCancellable?

    init() {
        visibilitySubscription = Publishers
            .Merge(
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillShowNotification)
                    .map { _ in true },
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardDidHideNotification)
                    .map { _ in false }
            )
            .assign(to: \.keyboardVisible, on: self, ownership: .weak)
    }

    func hideKeyboard(completion: @escaping () -> Void) {
        guard keyboardVisible else {
            completion()
            return
        }

        hideKeyboardSubscription = NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
            .sink { [weak self] _ in
                completion()
                self?.hideKeyboardSubscription = nil
            }

        UIApplication.shared.endEditing()
    }
}

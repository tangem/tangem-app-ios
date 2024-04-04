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
                    .publisher(for: UIResponder.keyboardWillHideNotification)
                    .map { _ in false }
            )
            .assign(to: \.keyboardVisible, on: self, ownership: .weak)
    }

    func hideKeyboard(completion: @escaping () -> Void) {
        hideKeyboardSubscription = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                print("zzz \(ttttt()) did hide")
                completion()
                self?.hideKeyboardSubscription = nil
            }

        UIApplication.shared.endEditing()
    }
}

// DELETE
// DELETE
// DELETE
// DELETE
// DELETE
// DELETE
// DELETE
// DELETE

func ttttt() -> String {
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    let dateString = formatter.string(from: date)
    return dateString
}

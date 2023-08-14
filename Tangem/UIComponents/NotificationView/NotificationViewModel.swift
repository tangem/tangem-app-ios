//
//  NotificationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct NotificationViewModel: Identifiable {
    // MARK: - Access

    var id: NotificationId { input.id }

    var style: NotificationView.Style { input.style }

    var colorScheme: NotificationView.ColorScheme { input.colorScheme }

    var icon: Image {
        input.icon.image
    }

    var iconColor: Color? {
        input.icon.color
    }

    var title: String {
        input.title
    }

    var description: String? {
        input.description
    }

    var isDismissable: Bool { input.isDismissable }

    // MARK: - Properties

    private let input: Input

    // MARK: - Init

    init(input: Input) {
        self.input = input
    }

    func dismiss() {
        input.dismissAction?(id)
    }
}

extension NotificationViewModel {
    struct Input: Identifiable, Hashable {
        let id: NotificationId = UUID().uuidString
        let style: NotificationView.Style
        let colorScheme: NotificationView.ColorScheme
        let icon: NotificationView.MessageIcon
        let title: String
        let description: String?
        let isDismissable: Bool
        let dismissAction: ((NotificationId) -> Void)?

        static func == (lhs: NotificationViewModel.Input, rhs: NotificationViewModel.Input) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

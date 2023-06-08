//
//  NotificationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct NotificationViewModel: Identifiable {
    // MARK: - Access

    public var mainIcon: ImageType {
        input.mainIcon
    }

    public var title: String {
        input.title
    }

    public var description: String? {
        input.description
    }

    public var detailIcon: ImageType? {
        input.detailIcon
    }

    // MARK: - Properties

    public let id = UUID()
    public let primaryTapAction: (() -> Void)?
    public let secondaryTapAction: (() -> Void)?

    private let input: Input

    // MARK: - Init

    public init(input: Input, primaryTapAction: (() -> Void)?, secondaryTapAction: (() -> Void)?) {
        self.input = input
        self.primaryTapAction = primaryTapAction
        self.secondaryTapAction = secondaryTapAction
    }
}

public extension NotificationViewModel {
    struct Input {
        let mainIcon: ImageType
        let title: String
        let description: String?
        let detailIcon: ImageType?
    }
}

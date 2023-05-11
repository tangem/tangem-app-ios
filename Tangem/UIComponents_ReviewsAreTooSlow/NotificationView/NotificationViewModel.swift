//
//  NotificationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct NotificationViewModel: Identifiable {
    public struct Input {
        let mainIcon: ImageType
        let title: String
        let description: String?
        let detailIcon: ImageType?
    }
    
    // MARK: - Properties

    public let id = UUID()

    private let input: Input
    public let primaryTapAction: (() -> Void)?
    public let secondaryTapAction: (() -> Void)?
    
    // MARK: - Init
    
    public init(input: Input, primaryTapAction: (@escaping () -> Void)?, secondaryTapAction: (@escaping () -> Void)?) {
        self.input = input
        self.primaryTapAction = primaryTapAction
        self.secondaryTapAction = secondaryTapAction
    }
    
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
}

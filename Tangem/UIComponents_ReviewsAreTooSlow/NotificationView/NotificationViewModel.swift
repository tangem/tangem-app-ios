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
        let moreIcon: ImageType?
    }

    public let id = UUID()

    let input: Input
    let primaryTapAction: (() -> Void)?
    let secondaryTapAction: (() -> Void)?
}

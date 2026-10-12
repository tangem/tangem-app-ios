//
//  StoryActionV2.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

public struct StoryActionV2: Equatable {
    public let id: String
    public let label: String
    public let style: ActionStyle
    public let target: ActionTarget
    /// Local decoration only — remote stories have no icon in the contract.
    public let icon: ImageType?

    public init(id: String, label: String, style: ActionStyle, target: ActionTarget, icon: ImageType? = nil) {
        self.id = id
        self.label = label
        self.style = style
        self.target = target
        self.icon = icon
    }
}

public enum ActionStyle: String, Equatable {
    case primary
    case secondary
}

public enum ActionTarget: Equatable {
    case screen(String)
    case web(String)
    case deeplink(String)
    case close

    public var analyticsType: StoryActionTargetType {
        switch self {
        case .screen: .screen
        case .web: .web
        case .deeplink: .deeplink
        case .close: .close
        }
    }

    public var destination: String? {
        switch self {
        case .screen(let value): value
        case .web(let value): URL(string: value)?.host ?? value
        case .deeplink(let value): value
        case .close: nil
        }
    }
}

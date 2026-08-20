//
//  StoryActionV2.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct StoryActionV2: Equatable {
    public let id: String
    public let label: String
    public let style: ActionStyle
    public let target: ActionTarget

    public init(id: String, label: String, style: ActionStyle, target: ActionTarget) {
        self.id = id
        self.label = label
        self.style = style
        self.target = target
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

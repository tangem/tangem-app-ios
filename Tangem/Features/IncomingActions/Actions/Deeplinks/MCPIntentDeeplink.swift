//
//  MCPIntentDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// `tangem://intent?id&source&type`
struct MCPIntentDeeplink: HostNamedDeeplink, Equatable {
    static let host = "intent"

    let id: String
    let source: String
    let type: String

    var action: DeeplinkNavigationAction { DeeplinkNavigationAction.mcpIntent(self) }
}

// MARK: - Parsing

extension MCPIntentDeeplink {
    private enum Keys: String {
        case source
        case type
    }

    init(link: DeeplinkURL) throws {
        id = try link.query.required(IncomingActionConstants.DeeplinkParams.id)
        source = try link.query.required(Keys.source.rawValue)
        type = try link.query.required(Keys.type.rawValue)
    }
}

extension MCPIntentDeeplink: CustomDebugStringConvertible {
    var debugDescription: String {
        "tangem://intent?id=\(id)&source=\(source)&type=\(type)"
    }
}

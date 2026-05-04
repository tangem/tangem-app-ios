//
//  OSLogCategory.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import OSLog

public struct OSLogCategory {
    public let name: String
    public let prefix: ((_ level: Logger.Level, _ option: Logger.PrefixOption) -> String)?

    /// Pre-built `os.Logger` for this category.
    let osLogger: os.Logger

    public init(
        name: String,
        prefix: ((_: Logger.Level, _: Logger.PrefixOption) -> String)? = {
            PrefixBuilder().prefix(level: $0, option: $1)
        }
    ) {
        self.name = name
        self.prefix = prefix
        osLogger = os.Logger(subsystem: OSLogConstants.subsystem, category: name.capitalized)
    }
}

// MARK: Tagable

extension OSLogCategory: Logger.Tagable {
    public func tag(_ tag: String) -> Self {
        OSLogCategory(name: "\(name) [\(tag)]", prefix: prefix)
    }
}

// MARK: - Hashable

extension OSLogCategory: Hashable {
    public static func == (lhs: OSLogCategory, rhs: OSLogCategory) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

// MARK: - PrefixBuilder

public extension OSLogCategory {
    struct PrefixBuilder {
        public init() {}
        public func prefix(level _: Logger.Level, option: Logger.PrefixOption) -> String {
            switch option {
            case .object(.none):
                return "<EmptyObject>"
            case .object(.some(let object)):
                return "\(object.description)"
            case .verbose(let file, let line, let function):
                let prefix = "\(URL(fileURLWithPath: file.description).deletingPathExtension().lastPathComponent):\(line):\(function)"
                return "<\(prefix)>"
            }
        }
    }
}

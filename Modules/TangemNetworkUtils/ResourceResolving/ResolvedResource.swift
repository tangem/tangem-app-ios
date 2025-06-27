//
//  ResolvedResource.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct UniformTypeIdentifiers.UTType

/// Represents a remote resource, including it's content type and optional raw data.
public struct ResolvedResource {
    /// The original ``URL`` of the resource.
    public let url: URL

    /// The resolved content type in ``UTType`` format.
    public let universalType: UTType

    /// The raw data of the resource.
    /// - Note: available only when a server does not support `Range` request.
    public let data: Data?

    public init(url: URL, universalType: UTType, data: Data?) {
        self.url = url
        self.universalType = universalType
        self.data = data
    }
}

//
//  NFTIPFSURLConverter.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Converts IPFS URLs (see https://en.wikipedia.org/wiki/InterPlanetary_File_System for details) into valid HTTPS URLs, if needed.
enum NFTIPFSURLConverter {
    static func convert(_ url: URL) -> URL {
        guard url.scheme == "ipfs" else {
            return url
        }

        var ipfsPath = [url.host, url.path]
            .compactMap { $0 }
            .filter(\.isNotEmpty)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }
            .joined(separator: "/")

        if !ipfsPath.hasPrefix("ipfs") {
            ipfsPath = "ipfs/" + ipfsPath
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "ipfs.io"
        components.path = "/\(ipfsPath)"
        components.query = url.query
        components.fragment = url.fragment

        return components.url ?? url
    }
}

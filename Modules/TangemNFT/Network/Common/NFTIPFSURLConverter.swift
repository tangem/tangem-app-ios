//
//  NFTIPFSURLConverter.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Converts IPFS URLs (see https://en.wikipedia.org/wiki/InterPlanetary_File_System for details) into valid HTTPS URLs, if needed.
enum NFTIPFSURLConverter {
    static func convert(_ url: URL) -> URL {
        guard
            url.scheme == "ipfs",
            let host = url.host
        else {
            return url
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "ipfs.io"
        components.path = "/ipfs/" + host

        return components.url ?? url
    }
}

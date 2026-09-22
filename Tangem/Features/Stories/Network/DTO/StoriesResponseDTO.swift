//
//  StoriesResponseDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// The response is a dictionary keyed by placement: `{ "main_upgrade": [stories] }`.
struct StoriesResponseDTO {
    let storiesByPlacement: [String: [StoryDTO]]

    struct StoryDTO: Decodable {
        let slug: String
        let language: String?
        let priority: Int?
        let displayPolicy: String?
        /// The backend example spells it `endBehaviour`; a rename is pending on their side.
        let endBehaviour: String?
        /// A malformed slide degrades to the mapper's slide-level drop, not a lost story.
        @LossyArray var slides: [SlideDTO]
        let actions: [ActionDTO]?
    }

    struct SlideDTO: Decodable {
        /// Numeric on the wire — the backend serves its own database id.
        let id: Int
        let title: String
        let subtitle: String?
        let assetType: String
        let contentMode: String?
        let durationMs: Int
        let hapticAtMs: [Int]?
        let source: SourceDTO?
        let poster: SourceDTO?
        /// Absent → nil (inherit); present [] → hide; non-empty → replace.
        let actions: [ActionDTO]?
    }

    struct SourceDTO: Decodable {
        let url: String
        let sizeBytes: Int?
        let checksum: String?
    }

    /// The target is flattened into per-kind fields; exactly one of them is expected.
    struct ActionDTO: Decodable {
        let id: Int?
        let label: String
        let style: String
        let deeplink: String?
        let url: String?
        let screen: String?
        let close: Bool?
    }
}

extension StoriesResponseDTO: Decodable {
    /// A malformed story is dropped instead of failing the placement, and a `null` placement
    /// decodes as absent instead of failing the whole response.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: LossyArray<StoryDTO>?].self)
        storiesByPlacement = raw.compactMapValues { $0?.wrappedValue }
    }
}

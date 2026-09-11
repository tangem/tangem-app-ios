//
//  StoriesResponseDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct StoriesResponseDTO: Decodable {
    let schemaVersion: Int
    let contentHost: String
    /// Malformed story is dropped instead of failing the whole response.
    @LossyArray var items: [StoryDTO]

    struct StoryDTO: Decodable {
        let id: String
        let version: Int
        let language: String
        let placements: [String]
        let priority: Int
        let displayPolicy: DisplayPolicyDTO
        let endBehavior: String
        let activeFrom: Date?
        let activeTo: Date?
        let actions: [ActionDTO]
        let slides: [SlideDTO]
    }

    struct DisplayPolicyDTO: Decodable {
        let type: String
        let scope: String?
        let resetOnVersion: Bool?
    }

    struct ActionDTO: Decodable {
        let id: String
        let label: String
        let style: String
        let target: TargetDTO
    }

    struct TargetDTO: Decodable {
        let type: String
        let value: String?
    }

    struct SlideDTO: Decodable {
        let id: String
        let order: Int
        let title: String
        let subtitle: String
        let asset: AssetDTO
        let hapticAtMs: [Int]?
        /// Absent → nil (inherit); present [] → hide; non-empty → replace.
        let actions: [ActionDTO]?
    }

    struct AssetDTO: Decodable {
        let type: String
        let contentMode: String
        let durationMs: Int
        let sources: [SourceDTO]
        let poster: PosterDTO?
    }

    struct SourceDTO: Decodable {
        let path: String
        let platforms: [String]
        let checksum: String
    }

    struct PosterDTO: Decodable {
        let path: String
        let checksum: String
    }
}

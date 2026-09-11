//
//  StoriesDTOMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStories

/// Unknown enums degrade — skip the slide, drop the story, or hide the action — never a silent default.
struct StoriesDTOMapper {
    private static let allowedContentSchemes: Set<String> = ["http", "https"]

    private let allowedWebHosts: Set<String>

    init(allowedWebHosts: Set<String>) {
        self.allowedWebHosts = Set(allowedWebHosts.map { $0.lowercased() })
    }

    func map(_ dto: StoriesResponseDTO) -> [StoryV2] {
        guard dto.schemaVersion == 1 else { return [] }
        return dto.items.compactMap { mapStory($0, host: dto.contentHost) }
    }

    // MARK: - Story

    private func mapStory(_ dto: StoriesResponseDTO.StoryDTO, host: String) -> StoryV2? {
        guard let displayPolicy = mapDisplayPolicy(dto.displayPolicy) else { return nil }
        guard let endBehavior = EndBehavior(rawValue: dto.endBehavior) else { return nil }
        guard !dto.placements.isEmpty else { return nil }

        let slides = dto.slides.compactMap { mapSlide($0, host: host) }
        guard !slides.isEmpty else { return nil }

        return StoryV2(
            id: dto.id,
            version: dto.version,
            language: dto.language,
            placements: dto.placements,
            priority: dto.priority,
            displayPolicy: displayPolicy,
            endBehavior: endBehavior,
            activeFrom: dto.activeFrom,
            activeTo: dto.activeTo,
            actions: dto.actions.compactMap(mapAction),
            slides: slides,
            origin: .remote
        )
    }

    private func mapDisplayPolicy(_ dto: StoriesResponseDTO.DisplayPolicyDTO) -> DisplayPolicy? {
        switch DisplayPolicy.Kind(rawValue: dto.type) {
        case .always:
            return .always
        case .once:
            guard let scope = dto.scope.flatMap(DisplayPolicy.Scope.init(rawValue:)),
                  let resetOnVersion = dto.resetOnVersion else { return nil }
            return .once(scope: scope, resetOnVersion: resetOnVersion)
        case nil:
            return nil
        }
    }

    // MARK: - Slide

    private func mapSlide(_ dto: StoriesResponseDTO.SlideDTO, host: String) -> SlideV2? {
        guard let type = AssetType(rawValue: dto.asset.type) else { return nil }
        guard let contentMode = StoryContentMode(rawValue: dto.asset.contentMode) else { return nil }
        guard let source = dto.asset.sources.first(where: isCompatible) else { return nil }
        guard let assetURL = url(host: host, path: source.path) else { return nil }

        let asset = AssetV2(
            type: type,
            contentMode: contentMode,
            durationMs: dto.asset.durationMs,
            url: assetURL,
            checksum: source.checksum,
            posterURL: dto.asset.poster.flatMap { url(host: host, path: $0.path) },
            posterChecksum: dto.asset.poster?.checksum ?? ""
        )

        return SlideV2(
            id: dto.id,
            order: dto.order,
            title: dto.title,
            subtitle: dto.subtitle,
            asset: asset,
            hapticAtMs: mapHaptics(dto.hapticAtMs, type: type, durationMs: dto.asset.durationMs),
            actions: mapSlideActions(dto.actions)
        )
    }

    /// Present-but-all-unknown collapses to inherit, not hide — the backend intent was "replace".
    private func mapSlideActions(_ dto: [StoriesResponseDTO.ActionDTO]?) -> [StoryActionV2]? {
        guard let dto else { return nil }
        let mapped = dto.compactMap(mapAction)
        return (!dto.isEmpty && mapped.isEmpty) ? nil : mapped
    }

    private func mapHaptics(_ raw: [Int]?, type: AssetType, durationMs: Int) -> [Int] {
        guard type != .image, durationMs > 0, let raw else { return [] }
        return Set(raw.filter { $0 >= 0 && $0 < durationMs }).sorted()
    }

    private func isCompatible(_ source: StoriesResponseDTO.SourceDTO) -> Bool {
        source.platforms.contains { raw in
            guard let platform = SourcePlatform(rawValue: raw) else { return false }
            return platform == .all || platform == .ios
        }
    }

    // MARK: - Action

    private func mapAction(_ dto: StoriesResponseDTO.ActionDTO) -> StoryActionV2? {
        guard let style = ActionStyle(rawValue: dto.style) else { return nil }
        guard let target = mapTarget(dto.target) else { return nil }
        return StoryActionV2(id: dto.id, label: dto.label, style: style, target: target)
    }

    private func mapTarget(_ dto: StoriesResponseDTO.TargetDTO) -> ActionTarget? {
        switch StoryActionTargetType(rawValue: dto.type) {
        case .close:
            return .close
        case .screen:
            guard let value = dto.value, !value.isEmpty else { return nil }
            return .screen(value)
        case .web:
            guard let value = dto.value,
                  let webURL = URL(string: value),
                  webURL.scheme?.lowercased() == "https",
                  let host = webURL.host?.lowercased(),
                  allowedWebHosts.contains(host) else { return nil }
            return .web(value)
        case .deeplink:
            guard let value = dto.value, !value.isEmpty else { return nil }
            return .deeplink(value)
        case nil:
            return nil
        }
    }

    // MARK: - URL

    private func url(host: String, path: String) -> URL? {
        if let direct = URL(string: path),
           let scheme = direct.scheme?.lowercased(),
           Self.allowedContentSchemes.contains(scheme) {
            return direct
        }
        guard !host.isEmpty else { return URL(string: path) }
        let normalizedHost = host.hasSuffix("/") ? String(host.dropLast()) : host
        let normalizedPath = path.hasPrefix("/") ? path : "/" + path
        return URL(string: normalizedHost + normalizedPath)
    }
}

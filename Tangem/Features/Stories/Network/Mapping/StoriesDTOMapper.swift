//
//  StoriesDTOMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemStories

/// Unknown enums degrade — skip the slide, drop the story, or hide the action — never a silent default.
struct StoriesDTOMapper {
    private let allowedWebHosts: Set<String>
    private let origin: ContentOrigin

    init(allowedWebHosts: Set<String>, origin: ContentOrigin) {
        self.allowedWebHosts = Set(allowedWebHosts.map { $0.lowercased() })
        self.origin = origin
    }

    /// Placement comes from the envelope key; a slug served under several placements collapses
    /// into one story carrying all of them, so `StoryV2.id` stays unique. Cross-placement order
    /// is made deterministic here (priority DESC, id ASC) because a dictionary carries none.
    func map(_ dto: StoriesResponseDTO) -> [StoryV2] {
        let occurrences = dto.storiesByPlacement
            .sorted { $0.key < $1.key }
            .flatMap { placement, stories in
                stories.map { (placement: placement, story: $0) }
            }

        return Dictionary(grouping: occurrences) { $0.story.slug }
            .values
            .compactMap { group in
                group.first.flatMap {
                    mapStory($0.story, placements: group.map(\.placement))
                }
            }
            .sorted { lhs, rhs in
                lhs.priority != rhs.priority ? lhs.priority > rhs.priority : lhs.id < rhs.id
            }
    }

    // MARK: - Story

    private func mapStory(_ dto: StoriesResponseDTO.StoryDTO, placements: [String]) -> StoryV2? {
        guard let displayPolicy = mapDisplayPolicy(dto.displayPolicy) else { return nil }
        guard let endBehavior = EndBehavior(rawValue: dto.endBehaviour ?? EndBehavior.finish.rawValue) else { return nil }

        let slides = dto.slides.enumerated().compactMap { index, slide in
            mapSlide(slide, order: index + 1, storySlug: dto.slug)
        }
        guard !slides.isEmpty else { return nil }

        return StoryV2(
            id: dto.slug,
            language: dto.language ?? Constants.defaultLanguage,
            placements: placements,
            priority: dto.priority ?? Constants.defaultPriority,
            displayPolicy: displayPolicy,
            endBehavior: endBehavior,
            actions: mapActions(dto.actions ?? [], namespace: dto.slug),
            slides: slides,
            origin: origin
        )
    }

    /// Absent policy falls back to `always`; an unknown one still drops the story.
    private func mapDisplayPolicy(_ raw: String?) -> DisplayPolicy? {
        guard let raw else { return .always }
        return DisplayPolicy(rawValue: raw)
    }

    // MARK: - Slide

    private func mapSlide(_ dto: StoriesResponseDTO.SlideDTO, order: Int, storySlug: String) -> SlideV2? {
        guard let type = AssetType(rawValue: dto.assetType),
              let contentMode = mapContentMode(dto.contentMode),
              let source = dto.source,
              let assetURL = contentURL(source.url),
              dto.durationMs > 0,
              source.sizeBytes ?? 1 > 0 else { return nil }

        let poster = dto.poster.flatMap { poster in
            contentURL(poster.url).map { (url: $0, checksum: poster.checksum ?? "") }
        }

        let asset = AssetV2(
            type: type,
            contentMode: contentMode,
            durationMs: dto.durationMs,
            url: assetURL,
            checksum: source.checksum ?? "",
            posterURL: poster?.url,
            posterChecksum: poster?.checksum ?? ""
        )

        return SlideV2(
            id: String(dto.id),
            order: order,
            title: dto.title,
            subtitle: dto.subtitle ?? "",
            asset: asset,
            hapticAtMs: mapHaptics(dto.hapticAtMs, type: type, durationMs: dto.durationMs),
            actions: mapSlideActions(dto.actions, namespace: "\(storySlug)_\(dto.id)")
        )
    }

    /// A missing mode defaults to `cover`; an unknown one drops the slide — never a silent default.
    private func mapContentMode(_ raw: String?) -> StoryContentMode? {
        guard let raw else { return Constants.defaultContentMode }
        return StoryContentMode(rawValue: raw)
    }

    private func mapHaptics(_ raw: [Int]?, type: AssetType, durationMs: Int) -> [Int] {
        guard type != .image, durationMs > 0, let raw else { return [] }
        return Set(raw.filter { $0 >= 0 && $0 < durationMs }).sorted()
    }

    // MARK: - Action

    /// Absent → nil (inherit); present [] → hide; present-but-all-unknown collapses back to
    /// inherit, not hide — the backend intent was "replace".
    private func mapSlideActions(_ dto: [StoriesResponseDTO.ActionDTO]?, namespace: String) -> [StoryActionV2]? {
        guard let dto else { return nil }
        let mapped = mapActions(dto, namespace: namespace)
        return (!dto.isEmpty && mapped.isEmpty) ? nil : mapped
    }

    private func mapActions(_ dto: [StoriesResponseDTO.ActionDTO], namespace: String) -> [StoryActionV2] {
        dto.enumerated().compactMap { index, action in
            mapAction(action, fallbackID: "\(namespace)_action_\(index + 1)")
        }
    }

    /// The example omits action ids, so a positional one is derived for analytics. It shifts if
    /// the backend reorders actions — a server-side id stays the preferred source (question to BE).
    private func mapAction(_ dto: StoriesResponseDTO.ActionDTO, fallbackID: String) -> StoryActionV2? {
        guard let style = ActionStyle(rawValue: dto.style) else { return nil }
        guard let target = mapTarget(dto) else { return nil }
        return StoryActionV2(id: dto.id.map(String.init) ?? fallbackID, label: dto.label, style: style, target: target)
    }

    private func mapTarget(_ dto: StoriesResponseDTO.ActionDTO) -> ActionTarget? {
        if let deeplink = dto.deeplink, !deeplink.isEmpty {
            return .deeplink(deeplink)
        }

        if let raw = dto.url {
            guard let webURL = contentURL(raw),
                  let host = webURL.host?.lowercased(),
                  allowedWebHosts.contains(host) else { return nil }
            return .web(raw)
        }

        if let screen = dto.screen, !screen.isEmpty {
            return .screen(screen)
        }

        if dto.close == true {
            return .close
        }

        return nil
    }

    // MARK: - URL

    private func contentURL(_ raw: String) -> URL? {
        guard let url = URL(string: raw),
              url.isHTTPS else { return nil }
        return url
    }
}

// MARK: - Constants

private extension StoriesDTOMapper {
    enum Constants {
        static let defaultLanguage = "en"
        static let defaultPriority = 0
        static let defaultContentMode: StoryContentMode = .cover
    }
}

//
//  StoriesDTOMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
import TangemStories
@testable import Tangem

@Suite("StoriesDTOMapperTests")
struct StoriesDTOMapperTests {
    private let allowedWebHosts: Set<String> = [
        "promo.tangem.com", "tangem.com", "www.tangem.com", "buy.tangem.com",
        "app.tangem.com", "tangem.surveysparrow.com", "feedback.tangem.com",
    ]

    private func map(_ json: String) throws -> [StoryV2] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(StoriesResponseDTO.self, from: Data(json.utf8))
        return StoriesDTOMapper(allowedWebHosts: allowedWebHosts).map(dto)
    }

    // MARK: - JSON builders (complete, contract-valid fragments)

    private func videoSlide(_ id: String, _ order: Int, path: String) -> String {
        """
        { "id": "\(id)", "order": \(order), "title": "t", "subtitle": "s",
          "asset": { "type": "video", "contentMode": "cover", "durationMs": 6000,
            "sources": [{ "path": "\(path)", "mimeType": "video/mp4", "platforms": ["all"], "sizeBytes": 1, "checksum": "sha256:a" }],
            "poster": { "path": "\(path).webp", "mimeType": "image/webp", "sizeBytes": 1, "checksum": "sha256:b" } } }
        """
    }

    private func imageSlide(_ id: String, _ order: Int, path: String) -> String {
        """
        { "id": "\(id)", "order": \(order), "title": "t", "subtitle": "s",
          "asset": { "type": "image", "contentMode": "contain", "durationMs": 5000,
            "sources": [{ "path": "\(path)", "mimeType": "image/webp", "platforms": ["all"], "sizeBytes": 1, "checksum": "sha256:c" }] } }
        """
    }

    private func envelope(schemaVersion: Int = 1, host: String = "", story: String) -> String {
        """
        { "schemaVersion": \(schemaVersion), "contentHost": "\(host)", "items": [\(story)] }
        """
    }

    private func story(
        id: String = "s",
        placements: String = #"["main_upgrade"]"#,
        priority: Int = 1,
        displayPolicy: String = #"{ "type": "always" }"#,
        endBehavior: String = "finish",
        actions: String = "[]",
        slides: String
    ) -> String {
        """
        { "id": "\(id)", "version": 1, "language": "en", "placements": \(placements),
          "priority": \(priority), "displayPolicy": \(displayPolicy), "endBehavior": "\(endBehavior)",
          "actions": \(actions), "slides": [\(slides)] }
        """
    }

    // MARK: - Tests

    @Test
    func unknownAssetTypeSlideIsSkipped() throws {
        let unknown = #"{ "id": "b", "order": 2, "title": "t", "subtitle": "s", "asset": { "type": "spline3d", "contentMode": "cover", "durationMs": 6000, "sources": [{ "path": "b.usdz", "mimeType": "model/usdz", "platforms": ["all"], "sizeBytes": 1, "checksum": "sha256:x" }] } }"#
        let action = #"[{ "id": "go", "label": "Go", "style": "primary", "target": { "type": "screen", "value": "hardware_wallet" } }]"#
        let stories = try map(envelope(host: "https://h/", story: story(
            actions: action,
            slides: "\(videoSlide("a", 1, path: "a.mp4")), \(unknown), \(imageSlide("c", 3, path: "c.webp"))"
        )))

        #expect(stories.count == 1)
        #expect(stories[0].slides.map(\.id) == ["a", "c"])
        #expect(stories[0].actions.first?.target == .screen("hardware_wallet"))
        #expect(stories[0].slides[0].asset.url == URL(string: "https://h/a.mp4"))
    }

    @Test
    func unknownContentModeSkipsSlide() throws {
        let weird = #"{ "id": "w", "order": 1, "title": "t", "subtitle": "s", "asset": { "type": "image", "contentMode": "parallax", "durationMs": 5000, "sources": [{ "path": "w.webp", "mimeType": "image/webp", "platforms": ["all"], "sizeBytes": 1, "checksum": "sha256:x" }] } }"#
        let stories = try map(envelope(story: story(slides: "\(weird), \(imageSlide("c", 2, path: "c.webp"))")))
        #expect(stories.first?.slides.map(\.id) == ["c"])
    }

    @Test
    func storyWithOnlyUnknownSlidesIsDropped() throws {
        let unknown = #"{ "id": "x", "order": 1, "title": "t", "subtitle": "s", "asset": { "type": "hologram", "contentMode": "cover", "durationMs": 6000, "sources": [{ "path": "x", "mimeType": "x", "platforms": ["all"], "sizeBytes": 1, "checksum": "sha256:x" }] } }"#
        let stories = try map(envelope(story: story(slides: unknown)))
        #expect(stories.isEmpty)
    }

    @Test
    func onceDisplayPolicyParsing() throws {
        let stories = try map(envelope(story: story(
            placements: #"["onboarding"]"#,
            displayPolicy: #"{ "type": "once", "scope": "device", "resetOnVersion": true }"#,
            endBehavior: "loop",
            actions: #"[{ "id": "start", "label": "Start", "style": "primary", "target": { "type": "close" } }]"#,
            slides: imageSlide("s", 1, path: "s.webp")
        )))
        #expect(stories.first?.endBehavior == .loop)
        #expect(stories.first?.displayPolicy.type == .once)
        #expect(stories.first?.displayPolicy.scope == .device)
        #expect(stories.first?.displayPolicy.resetOnVersion == true)
        #expect(stories.first?.actions.first?.target == .close)
    }

    @Test
    func onceWithoutScopeDropsStory() throws {
        let stories = try map(envelope(story: story(
            displayPolicy: #"{ "type": "once" }"#,
            slides: imageSlide("s", 1, path: "s.webp")
        )))
        #expect(stories.isEmpty)
    }

    @Test
    func unknownDisplayPolicyDropsStory() throws {
        let stories = try map(envelope(story: story(
            displayPolicy: #"{ "type": "weekly" }"#,
            slides: videoSlide("a", 1, path: "a.mp4")
        )))
        #expect(stories.isEmpty)
    }

    @Test
    func placementsKeptVerbatim() throws {
        let stories = try map(envelope(story: story(
            placements: #"["telepathy", "main_upgrade"]"#,
            slides: videoSlide("a", 1, path: "a.mp4")
        )))
        #expect(stories.first?.placements == ["telepathy", "main_upgrade"])
    }

    @Test
    func emptyPlacementsDropsStory() throws {
        let stories = try map(envelope(story: story(
            placements: "[]",
            slides: videoSlide("a", 1, path: "a.mp4")
        )))
        #expect(stories.isEmpty)
    }

    @Test
    func forbiddenWebTargetActionHidden() throws {
        let actions = """
        [
          { "id": "bad", "label": "Evil", "style": "primary", "target": { "type": "web", "value": "https://evil.com/x" } },
          { "id": "ok", "label": "Buy", "style": "secondary", "target": { "type": "web", "value": "https://buy.tangem.com/promo" } }
        ]
        """
        let stories = try map(envelope(story: story(actions: actions, slides: videoSlide("a", 1, path: "a.mp4"))))
        #expect(stories.first?.actions.map(\.id) == ["ok"])
        #expect(stories.first?.actions.first?.target == .web("https://buy.tangem.com/promo"))
    }

    @Test
    func httpWebTargetActionHidden() throws {
        let actions = #"[{ "id": "http", "label": "Plain", "style": "primary", "target": { "type": "web", "value": "http://buy.tangem.com/promo" } }]"#
        let stories = try map(envelope(story: story(actions: actions, slides: videoSlide("a", 1, path: "a.mp4"))))
        #expect(stories.first?.actions.isEmpty == true)
    }

    @Test
    func webHostAllowlistIsCaseInsensitive() throws {
        let actions = #"[{ "id": "ok", "label": "Buy", "style": "primary", "target": { "type": "web", "value": "https://Buy.Tangem.com/promo" } }]"#
        let stories = try map(envelope(story: story(actions: actions, slides: videoSlide("a", 1, path: "a.mp4"))))
        #expect(stories.first?.actions.first?.target == .web("https://Buy.Tangem.com/promo"))
    }

    @Test
    func unknownActionStyleHidden() throws {
        let actions = #"[{ "id": "t", "label": "T", "style": "tertiary", "target": { "type": "close" } }]"#
        let stories = try map(envelope(story: story(actions: actions, slides: videoSlide("a", 1, path: "a.mp4"))))
        #expect(stories.first?.actions.isEmpty == true)
    }

    @Test
    func schemaVersionMismatchYieldsNothing() throws {
        let stories = try map(envelope(schemaVersion: 2, story: story(slides: videoSlide("a", 1, path: "a.mp4"))))
        #expect(stories.isEmpty)
    }

    @Test
    func malformedStoryInArrayIsSkipped() throws {
        // `bad` omits the required endBehavior → dropped at decode; `good` survives.
        let good = story(id: "good", slides: videoSlide("a", 1, path: "a.mp4"))
        let bad = """
        { "id": "bad", "version": 1, "language": "en", "placements": ["main_upgrade"],
          "priority": 1, "displayPolicy": { "type": "always" }, "actions": [],
          "slides": [\(videoSlide("z", 1, path: "z.mp4"))] }
        """
        let stories = try map(envelope(story: "\(good), \(bad)"))
        #expect(stories.map(\.id) == ["good"])
    }

    @Test
    func emptyItems() throws {
        let stories = try map(#"{ "schemaVersion": 1, "contentHost": "", "items": [] }"#)
        #expect(stories.isEmpty)
    }

    // MARK: - URL resolution

    @Test
    func hostWithoutTrailingSlashIsNormalized() throws {
        let stories = try map(envelope(host: "https://cdn.tangem.com", story: story(slides: videoSlide("a", 1, path: "a.mp4"))))
        #expect(stories.first?.slides.first?.asset.url == URL(string: "https://cdn.tangem.com/a.mp4"))
    }

    @Test
    func hostAndPathBothWithSlashesProduceSingleSeparator() throws {
        let stories = try map(envelope(host: "https://cdn.tangem.com/", story: story(slides: videoSlide("a", 1, path: "/a.mp4"))))
        #expect(stories.first?.slides.first?.asset.url == URL(string: "https://cdn.tangem.com/a.mp4"))
    }

    @Test
    func absoluteHttpsSourcePathBypassesHost() throws {
        let stories = try map(envelope(host: "https://ignored.example/", story: story(slides: videoSlide("a", 1, path: "https://other.example/x.mp4"))))
        #expect(stories.first?.slides.first?.asset.url == URL(string: "https://other.example/x.mp4"))
    }

    @Test
    func schemeLikePathIsResolvedAgainstHost() throws {
        let stories = try map(envelope(host: "https://cdn.tangem.com/", story: story(slides: videoSlide("a", 1, path: "sha256:abc.mp4"))))
        #expect(stories.first?.slides.first?.asset.url == URL(string: "https://cdn.tangem.com/sha256:abc.mp4"))
    }

    @Test
    func unresolvableAssetURLDropsSlide() throws {
        let unresolvable = #"{ "id": "u", "order": 1, "title": "t", "subtitle": "s", "asset": { "type": "video", "contentMode": "cover", "durationMs": 5000, "sources": [{ "path": "", "mimeType": "video/mp4", "platforms": ["all"], "sizeBytes": 1, "checksum": "sha256:x" }] } }"#
        let stories = try map(envelope(host: "", story: story(slides: "\(unresolvable), \(imageSlide("c", 2, path: "c.webp"))")))
        #expect(stories.first?.slides.map(\.id) == ["c"])
    }

    // MARK: - Slide actions (absent → inherit; [] → hide; non-empty → replace)

    @Test
    func slideActionsAbsentInheritsFromStory() throws {
        let slide = #"{ "id": "a", "order": 1, "title": "t", "subtitle": "s", "asset": { "type": "image", "contentMode": "cover", "durationMs": 5000, "sources": [{ "path": "a.webp", "mimeType": "image/webp", "platforms": ["all"], "sizeBytes": 1, "checksum": "sha256:c" }] } }"#
        let stories = try map(envelope(host: "https://h/", story: story(
            actions: #"[{ "id": "s", "label": "S", "style": "primary", "target": { "type": "close" } }]"#,
            slides: slide
        )))
        #expect(stories.first?.slides.first?.actions == nil)
    }

    @Test
    func slideActionsExplicitEmptyHidesStoryLevel() throws {
        let slide = #"{ "id": "a", "order": 1, "title": "t", "subtitle": "s", "actions": [], "asset": { "type": "image", "contentMode": "cover", "durationMs": 5000, "sources": [{ "path": "a.webp", "mimeType": "image/webp", "platforms": ["all"], "sizeBytes": 1, "checksum": "sha256:c" }] } }"#
        let stories = try map(envelope(host: "https://h/", story: story(slides: slide)))
        #expect(stories.first?.slides.first?.actions == [])
    }

    @Test
    func slideActionsAllUnknownInheritsInsteadOfHiding() throws {
        let slide = #"""
        { "id": "a", "order": 1, "title": "t", "subtitle": "s",
          "actions": [{ "id": "t", "label": "T", "style": "tertiary", "target": { "type": "close" } }],
          "asset": { "type": "image", "contentMode": "cover", "durationMs": 5000, "sources": [{ "path": "a.webp", "mimeType": "image/webp", "platforms": ["all"], "sizeBytes": 1, "checksum": "sha256:c" }] } }
        """#
        let stories = try map(envelope(host: "https://h/", story: story(slides: slide)))
        #expect(stories.first?.slides.first?.actions == nil)
    }

    // MARK: - Haptics

    @Test
    func zeroDurationStripsHaptics() throws {
        let slide = #"""
        { "id": "a", "order": 1, "title": "t", "subtitle": "s",
          "hapticAtMs": [100, 200],
          "asset": { "type": "video", "contentMode": "cover", "durationMs": 0,
            "sources": [{ "path": "a.mp4", "mimeType": "video/mp4", "platforms": ["all"], "sizeBytes": 1, "checksum": "sha256:x" }] } }
        """#
        let stories = try map(envelope(host: "https://h/", story: story(slides: slide)))
        #expect(stories.first?.slides.first?.hapticAtMs == [])
    }

    @Test
    func hapticsDedupedAndSorted() throws {
        let slide = #"""
        { "id": "a", "order": 1, "title": "t", "subtitle": "s",
          "hapticAtMs": [200, 100, 200, -5, 6000],
          "asset": { "type": "video", "contentMode": "cover", "durationMs": 6000,
            "sources": [{ "path": "a.mp4", "mimeType": "video/mp4", "platforms": ["all"], "sizeBytes": 1, "checksum": "sha256:x" }] } }
        """#
        let stories = try map(envelope(host: "https://h/", story: story(slides: slide)))
        #expect(stories.first?.slides.first?.hapticAtMs == [100, 200])
    }
}

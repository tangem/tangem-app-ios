//
//  StoriesDTOMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemStories
@testable import Tangem

@Suite("StoriesDTOMapperTests")
struct StoriesDTOMapperTests {
    private let allowedWebHosts: Set<String> = [
        "promo.tangem.com", "tangem.com", "www.tangem.com", "buy.tangem.com",
        "app.tangem.com", "tangem.surveysparrow.com", "feedback.tangem.com",
    ]

    private func map(_ json: String, origin: ContentOrigin = .remote) throws -> [StoryV2] {
        let dto = try JSONDecoder().decode(StoriesResponseDTO.self, from: Data(json.utf8))
        return StoriesDTOMapper(allowedWebHosts: allowedWebHosts, origin: origin).map(dto)
    }

    // MARK: - Backend example

    @Test
    func mapsBackendExample() throws {
        let stories = try map(Self.backendExample)

        let story = try #require(stories.first)
        #expect(stories.count == 1)
        #expect(story.id == "hardware_upgrade")
        #expect(story.placements == ["main_upgrade"])
        #expect(story.priority == 100)
        #expect(story.displayPolicy == .always)
        #expect(story.endBehavior == .finish)
        #expect(story.origin == .remote)

        #expect(story.slides.count == 2)
        let first = story.slides[0]
        #expect(first.id == "2")
        #expect(first.order == 1)
        #expect(first.asset.type == .video)
        #expect(first.asset.contentMode == .cover)
        #expect(first.asset.durationMs == 10000)
        #expect(first.hapticAtMs == [1200])
        #expect(first.asset.url?.absoluteString.hasSuffix("8f3c21d9.mp4") == true)
        #expect(story.slides[1].order == 2)
        #expect(story.slides[1].hapticAtMs.isEmpty)

        let action = try #require(story.actions.first)
        #expect(action.id == "hardware_upgrade_action_1")
        #expect(action.label == "Get Tangem")
        #expect(action.style == .primary)
        #expect(action.target == .deeplink("tangem://hardware_wallet"))
    }

    // MARK: - Story fields

    @Test
    func mapsEndBehaviourSpelling() throws {
        let stories = try map(Self.story(extra: #""endBehaviour": "loop""#))

        #expect(stories.first?.endBehavior == .loop)
    }

    @Test
    func missingPolicyAndBehaviorFallBackToDefaults() throws {
        let story = try #require(try map(Self.story()).first)

        #expect(story.displayPolicy == .always)
        #expect(story.endBehavior == .finish)
    }

    @Test
    func unknownDisplayPolicyDropsStory() throws {
        #expect(try map(Self.story(extra: #""displayPolicy": "sometimes""#)).isEmpty)
    }

    @Test
    func unknownEndBehaviorDropsStory() throws {
        #expect(try map(Self.story(extra: #""endBehaviour": "restart""#)).isEmpty)
    }

    @Test
    func malformedStoryIsDroppedWithoutFailingThePlacement() throws {
        let json = """
        { "main": [
            { "language": "en", "slides": [] },
            \(Self.storyObject())
        ] }
        """
        let stories = try map(json)

        #expect(stories.count == 1)
        #expect(stories.first?.id == "slug_1")
    }

    @Test
    func nullPlacementIsSkippedNotFatal() throws {
        let json = """
        { "empty": null, "main": [\(Self.storyObject())] }
        """
        let stories = try map(json)

        #expect(stories.count == 1)
    }

    @Test
    func malformedSlideIsDroppedWithoutLosingTheStory() throws {
        let broken = #"{ "id": 99, "assetType": "video", "durationMs": 1000 }"#
        let stories = try map(Self.story(slides: [broken, Self.slideObject()]))

        #expect(stories.first?.slides.count == 1)
    }

    @Test
    func sameSlugAcrossPlacementsMergesIntoOneStory() throws {
        let json = """
        {
          "b_placement": [\(Self.storyObject(slug: "shared"))],
          "a_placement": [\(Self.storyObject(slug: "shared"))]
        }
        """
        let stories = try map(json)

        #expect(stories.count == 1)
        #expect(stories.first?.placements == ["a_placement", "b_placement"])
    }

    @Test
    func nonPositiveDurationDropsSlide() throws {
        let json = Self.story(slides: [Self.slideObject(durationMs: 0)])
        #expect(try map(json).isEmpty)
    }

    @Test
    func slideActionFallbackIdIsNamespacedByStoryAndSlide() throws {
        let slide = Self.slideObject(extra: #""actions": [{ "label": "Go", "style": "primary", "deeplink": "tangem://x" }]"#)
        let mapped = try #require(try map(Self.story(slides: [slide])).first?.slides.first)

        #expect(mapped.actions?.first?.id == "slug_1_7_action_1")
    }

    @Test
    func crossPlacementOrderIsPriorityDescThenIdAsc() throws {
        let json = """
        {
          "b_placement": [\(Self.storyObject(slug: "beta", extra: #""priority": 10"#))],
          "a_placement": [
            \(Self.storyObject(slug: "zeta", extra: #""priority": 100"#)),
            \(Self.storyObject(slug: "alpha", extra: #""priority": 10"#))
          ]
        }
        """
        let stories = try map(json)

        #expect(stories.map(\.id) == ["zeta", "alpha", "beta"])
    }

    // MARK: - Slides

    @Test
    func nonHTTPSSourceDropsSlideAndEmptyStory() throws {
        let slide = Self.slideObject(url: "http://cdn.example.com/a.mp4")
        #expect(try map(Self.story(slides: [slide])).isEmpty)
    }

    @Test
    func nonPositiveSizeBytesDropsSlide() throws {
        let slide = Self.slideObject(extraSource: #""sizeBytes": 0"#)
        #expect(try map(Self.story(slides: [slide])).isEmpty)
    }

    @Test
    func missingChecksumBecomesEmptyAndPosterStaysNil() throws {
        let asset = try #require(try map(Self.story()).first?.slides.first?.asset)

        #expect(asset.checksum.isEmpty)
        #expect(asset.posterURL == nil)
        #expect(asset.posterChecksum.isEmpty)
    }

    @Test
    func hapticsOutsideDurationAreFiltered() throws {
        let slide = Self.slideObject(extra: #""hapticAtMs": [-5, 100, 5000, 12000]"#)
        let mapped = try #require(try map(Self.story(slides: [slide])).first?.slides.first)

        #expect(mapped.hapticAtMs == [100, 5000])
    }

    @Test
    func unknownContentModeDropsSlideButMissingDefaultsToCover() throws {
        let unknown = try map(Self.story(slides: [Self.slideObject(contentMode: #""contentMode": "stretch","#)]))
        let missing = try map(Self.story(slides: [Self.slideObject(contentMode: "")]))

        #expect(unknown.isEmpty)
        #expect(missing.first?.slides.first?.asset.contentMode == .cover)
    }

    @Test
    func unknownAssetTypeDropsSlide() throws {
        let slide = Self.slideObject(assetType: "hologram")
        #expect(try map(Self.story(slides: [slide])).isEmpty)
    }

    // MARK: - Actions

    @Test
    func mapsFlattenedTargets() throws {
        let json = Self.story(actions: [
            #"{ "label": "Web", "style": "secondary", "url": "https://buy.tangem.com/x" }"#,
            #"{ "label": "Screen", "style": "secondary", "screen": "hardware_wallet" }"#,
            #"{ "label": "Close", "style": "secondary", "close": true }"#,
        ])
        let actions = try #require(try map(json).first?.actions)

        #expect(actions.map(\.target) == [
            .web("https://buy.tangem.com/x"),
            .screen("hardware_wallet"),
            .close,
        ])
    }

    @Test
    func disallowedWebHostDropsAction() throws {
        let json = Self.story(actions: [#"{ "label": "Web", "style": "secondary", "url": "https://evil.example.com" }"#])
        #expect(try map(json).first?.actions.isEmpty == true)
    }

    @Test
    func actionWithoutAnyTargetIsDropped() throws {
        let json = Self.story(actions: [#"{ "label": "Nothing", "style": "primary" }"#])
        #expect(try map(json).first?.actions.isEmpty == true)
    }

    @Test
    func explicitActionIdWinsOverFallback() throws {
        let json = Self.story(actions: [#"{ "id": 42, "label": "Go", "style": "primary", "deeplink": "tangem://x" }"#])
        #expect(try map(json).first?.actions.first?.id == "42")
    }

    @Test
    func slideActionsKeepInheritHideReplaceSemantics() throws {
        let inherit = Self.slideObject()
        let hide = Self.slideObject(extra: #""actions": []"#)
        let unknownOnly = Self.slideObject(extra: #""actions": [{ "label": "X", "style": "fancy", "deeplink": "tangem://x" }]"#)

        let slides = try #require(try map(Self.story(slides: [inherit, hide, unknownOnly])).first?.slides)

        #expect(slides[0].actions == nil)
        #expect(slides[1].actions == [])
        #expect(slides[2].actions == nil)
    }

    // MARK: - Fixtures

    private static func slideObject(
        url: String = "https://s3.example.com/stories/a.mp4",
        assetType: String = "video",
        contentMode: String = #""contentMode": "cover","#,
        durationMs: Int = 10000,
        extraSource: String = #""sizeBytes": 1000"#,
        extra: String = #""hapticAtMs": []"#
    ) -> String {
        """
        {
          "id": 7,
          "title": "Title",
          "subtitle": "Subtitle",
          "assetType": "\(assetType)",
          \(contentMode)
          "durationMs": \(durationMs),
          \(extra),
          "source": { "url": "\(url)", \(extraSource) }
        }
        """
    }

    private static func storyObject(
        slug: String = "slug_1",
        extra: String = #""language": "en""#,
        slides: [String]? = nil,
        actions: [String] = []
    ) -> String {
        """
        {
          "slug": "\(slug)",
          \(extra),
          "slides": [\((slides ?? [slideObject()]).joined(separator: ","))],
          "actions": [\(actions.joined(separator: ","))]
        }
        """
    }

    private static func story(
        extra: String = #""language": "en""#,
        slides: [String]? = nil,
        actions: [String] = []
    ) -> String {
        #"{ "main": [\#(storyObject(extra: extra, slides: slides, actions: actions))] }"#
    }

    private static let backendExample = """
    {
      "main_upgrade": [
        {
          "slug": "hardware_upgrade",
          "language": "en",
          "priority": 100,
          "displayPolicy": "always",
          "endBehaviour": "finish",
          "slides": [
            {
              "id": 2,
              "title": "One tap to control crypto",
              "subtitle": "Confirm every action with your Tangem",
              "assetType": "video",
              "contentMode": "cover",
              "durationMs": 10000,
              "hapticAtMs": [1200],
              "source": {
                "url": "https://s3.eu-central-1.amazonaws.com/tangem.api/stories/hardware_upgrade/8f3c21d9.mp4",
                "mimetype": "video/mp4",
                "codec": "avc1.4d003c",
                "sizeBytes": 2955524
              }
            },
            {
              "id": 3,
              "title": "Trusted by millions",
              "subtitle": "Join the self-custody wallet used worldwide",
              "assetType": "video",
              "contentMode": "cover",
              "durationMs": 10017,
              "source": {
                "url": "https://s3.eu-central-1.amazonaws.com/tangem.api/stories/hardware_upgrade/1d5fb7c3.mp4",
                "mimetype": "video/mp4",
                "codec": "avc1.4d003c",
                "sizeBytes": 2521474
              }
            }
          ],
          "actions": [
            { "label": "Get Tangem", "style": "primary", "deeplink": "tangem://hardware_wallet" }
          ]
        }
      ]
    }
    """
}

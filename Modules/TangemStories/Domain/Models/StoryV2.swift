//
//  StoryV2.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct StoryV2: Identifiable, Equatable {
    public let id: String
    public let version: Int
    public let language: String
    public let placements: [StoryPlacement]
    public let priority: Int
    public let displayPolicy: DisplayPolicy
    public let endBehavior: EndBehavior
    public let activeFrom: Date?
    public let activeTo: Date?
    public let actions: [StoryActionV2]
    public let slides: [SlideV2]
    public let origin: ContentOrigin

    public init(
        id: String,
        version: Int,
        language: String = "en",
        placements: [StoryPlacement] = [],
        priority: Int = 0,
        displayPolicy: DisplayPolicy = .always,
        endBehavior: EndBehavior,
        activeFrom: Date? = nil,
        activeTo: Date? = nil,
        actions: [StoryActionV2] = [],
        slides: [SlideV2],
        origin: ContentOrigin
    ) {
        self.id = id
        self.version = version
        self.language = language
        self.placements = placements
        self.priority = priority
        self.displayPolicy = displayPolicy
        self.endBehavior = endBehavior
        self.activeFrom = activeFrom
        self.activeTo = activeTo
        self.actions = actions
        self.slides = slides
        self.origin = origin
    }

    public func replacingSlides(_ slides: [SlideV2]) -> StoryV2 {
        StoryV2(
            id: id, version: version, language: language, placements: placements,
            priority: priority, displayPolicy: displayPolicy, endBehavior: endBehavior,
            activeFrom: activeFrom, activeTo: activeTo, actions: actions, slides: slides, origin: origin
        )
    }
}

public enum EndBehavior: String, Equatable {
    case finish
    case loop
}

public enum ContentOrigin: String, Equatable {
    case bundled
    case remote
}

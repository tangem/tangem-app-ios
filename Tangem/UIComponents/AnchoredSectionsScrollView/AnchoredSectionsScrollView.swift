//
//  AnchoredSectionsScrollView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct AnchoredSectionsScrollView<Section: TabNavigationItem, Header: View, Content: View>: View {
    private let sections: [Section]
    private let ignoresTopSafeArea: Bool
    private let header: (AnchoredSectionsViewport) -> Header
    private let content: Content

    @Binding private var isTabsPinned: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentSection: Section
    @State private var pendingSection: Section?
    @State private var settledContentOffset: CGFloat?
    @State private var viewport = AnchoredSectionsViewport.zero
    @State private var scrollFrames = ScrollFrames<Section>()

    init(
        sections: [Section],
        isTabsPinned: Binding<Bool>,
        ignoresTopSafeArea: Bool = false,
        @ViewBuilder header: @escaping (AnchoredSectionsViewport) -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.sections = sections
        self.ignoresTopSafeArea = ignoresTopSafeArea
        self.header = header
        self.content = content()
        _isTabsPinned = isTabsPinned
        _currentSection = State(initialValue: sections[0])
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    header(viewport)

                    tabs(proxy)
                        .scrollMarker(ScrollMarker<Section>.tabs)
                        .scrollMarker(ScrollMarker<Section>.tabsOnScreen, in: .global)
                        .opacity(isTabsPinned ? 0 : 1)
                        .accessibilityHidden(isTabsPinned)
                        .padding(.top, AnchoredSectionsConstants.spacing)

                    content
                        .padding(.top, AnchoredSectionsConstants.spacing)
                }
                .scrollMarker(ScrollMarker<Section>.content)
            }
            .coordinateSpace(name: AnchoredSections.coordinateSpace)
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: ignoresTopSafeArea ? .top : [])
            .scrollMarker(ScrollMarker<Section>.viewport, in: .local)
            .scrollMarker(ScrollMarker<Section>.viewportOnScreen, in: .global)
            .overlay(alignment: .top) {
                ZStack(alignment: .top) {
                    Color.clear
                        .frame(height: 0)
                        .scrollMarker(ScrollMarker<Section>.pinnedEdge, in: .global)

                    pinnedTabs(proxy)
                }
            }
            .onPreferenceChange(ScrollMarkersKey<Section>.self, perform: updateLayout)
        }
    }
}

// MARK: - Sections

extension View {
    func anchoredSection<Section: Hashable>(_ section: Section) -> some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 0)
                .id(SectionAnchor(section: section))
                .scrollMarker(ScrollMarker<Section>.section(section))

            self
        }
    }
}

enum AnchoredSections {
    static let coordinateSpace = "AnchoredSectionsScroll"

    static func current<Section: Hashable>(
        in sections: [Section],
        sectionTops: [Section: CGFloat],
        pinnedEdge: CGFloat,
        visibleBottom: CGFloat,
        remainingScroll: CGFloat
    ) -> Section? {
        let line = pinnedEdge + max(0, visibleBottom - pinnedEdge - remainingScroll)

        return sections.last { section in
            sectionTops[section, default: .infinity] <= line
        } ?? sections.first
    }
}

struct AnchoredSectionsViewport: Equatable {
    static let zero = AnchoredSectionsViewport(frame: .zero, safeAreaInsets: EdgeInsets())

    let frame: CGRect
    let safeAreaInsets: EdgeInsets
}

// MARK: - Tabs

private extension AnchoredSectionsScrollView {
    func tabs(_ proxy: ScrollViewProxy) -> some View {
        TabNavigation(data: sections, selection: sectionBinding(proxy))
            .scrollable()
            .padding(.horizontal, AnchoredSectionsConstants.tabsExtraHorizontalPadding)
    }

    func pinnedTabs(_ proxy: ScrollViewProxy) -> some View {
        tabs(proxy)
            .padding(.vertical, AnchoredSectionsConstants.pinnedTabsVerticalPadding)
            .opacity(isTabsPinned ? 1 : 0)
            .background {
                Fade(position: .top)
                    .variant(reduceTransparency ? .hard : .soft)
                    .blurred(!reduceTransparency)
                    .padding(.bottom, -AnchoredSectionsConstants.pinnedFadeTail)
                    .ignoresSafeArea(edges: .top)
                    .opacity(isTabsPinned ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeInOut(duration: AnchoredSectionsConstants.pinnedFadeDuration), value: isTabsPinned)
            }
            .allowsHitTesting(isTabsPinned)
            .accessibilityHidden(!isTabsPinned)
    }

    func sectionBinding(_ proxy: ScrollViewProxy) -> Binding<Section> {
        Binding(
            get: { currentSection },
            set: { section in
                currentSection = section
                pendingSection = section
                settledContentOffset = nil

                withAnimation(reduceMotion ? nil : .easeInOut(duration: AnchoredSectionsConstants.scrollDuration)) {
                    proxy.scrollTo(SectionAnchor(section: section), anchor: sectionAnchor)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + AnchoredSectionsConstants.scrollSettleDelay) {
                    if pendingSection == section {
                        settledContentOffset = scrollFrames.values[.content]?.minY
                    }
                }
            }
        )
    }

    var pinnedEdgeOffset: CGFloat {
        guard let pinnedEdge = scrollFrames.values[.pinnedEdge], let scrollView = scrollFrames.values[.viewportOnScreen] else {
            return viewport.safeAreaInsets.top
        }

        return pinnedEdge.minY - scrollView.minY
    }

    var sectionsEdge: CGFloat {
        pinnedEdgeOffset
            + (scrollFrames.values[.tabs]?.height ?? 0)
            + AnchoredSectionsConstants.pinnedTabsVerticalPadding * 2
    }

    var visibleBottom: CGFloat {
        viewport.safeAreaInsets.top + viewport.frame.height
    }

    var sectionAnchor: UnitPoint {
        guard visibleBottom > 0 else {
            return .top
        }

        return UnitPoint(x: 0.5, y: sectionsEdge / visibleBottom)
    }

    func updateLayout(_ measurements: [ScrollMarker<Section>: AnchoredSectionsViewport]) {
        if let measuredViewport = measurements[.viewport], measuredViewport != viewport {
            viewport = measuredViewport
        }

        scrollFrames.values = measurements.mapValues(\.frame)
        releasePendingSectionOnUserScroll()

        if let tabsOnScreen = scrollFrames.values[.tabsOnScreen], let pinnedEdge = scrollFrames.values[.pinnedEdge] {
            let isPinned = tabsOnScreen.minY <= pinnedEdge.minY + AnchoredSectionsConstants.pinnedTabsVerticalPadding

            if isPinned != isTabsPinned {
                isTabsPinned = isPinned
            }
        }

        updateCurrentSection()
    }

    func releasePendingSectionOnUserScroll() {
        guard let settledContentOffset, let contentOffset = scrollFrames.values[.content]?.minY else {
            return
        }

        if abs(contentOffset - settledContentOffset) > AnchoredSectionsConstants.userScrollThreshold {
            pendingSection = nil
            self.settledContentOffset = nil
        }
    }

    func updateCurrentSection() {
        guard pendingSection == nil, let contentBottom = scrollFrames.values[.content]?.maxY else {
            return
        }

        let sectionTops = Dictionary(uniqueKeysWithValues: sections.map { section in
            (section, scrollFrames.values[.section(section)]?.minY ?? .infinity)
        })

        let section = AnchoredSections.current(
            in: sections,
            sectionTops: sectionTops,
            pinnedEdge: sectionsEdge + AnchoredSectionsConstants.sectionEdgeTolerance,
            visibleBottom: visibleBottom,
            remainingScroll: contentBottom - visibleBottom
        )

        if let section, section != currentSection {
            currentSection = section
        }
    }
}

// MARK: - Scroll geometry

private struct SectionAnchor<Section: Hashable>: Hashable {
    let section: Section
}

private final class ScrollFrames<Section: Hashable> {
    var values: [ScrollMarker<Section>: CGRect] = [:]
}

private enum ScrollMarker<Section: Hashable>: Hashable {
    case viewport
    case viewportOnScreen
    case pinnedEdge
    case content
    case tabs
    case tabsOnScreen
    case section(Section)
}

private struct ScrollMarkersKey<Section: Hashable>: PreferenceKey {
    static var defaultValue: [ScrollMarker<Section>: AnchoredSectionsViewport] { [:] }

    static func reduce(
        value: inout [ScrollMarker<Section>: AnchoredSectionsViewport],
        nextValue: () -> [ScrollMarker<Section>: AnchoredSectionsViewport]
    ) {
        value.merge(nextValue()) { $1 }
    }
}

private extension View {
    func scrollMarker<Section: Hashable>(
        _ marker: ScrollMarker<Section>,
        in coordinateSpace: CoordinateSpace = .named(AnchoredSections.coordinateSpace)
    ) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ScrollMarkersKey<Section>.self,
                    value: [marker: AnchoredSectionsViewport(frame: proxy.frame(in: coordinateSpace), safeAreaInsets: proxy.safeAreaInsets)]
                )
            }
        }
    }
}

// MARK: - Constants

private enum AnchoredSectionsConstants {
    static let spacing: CGFloat = 24
    static let tabsExtraHorizontalPadding: CGFloat = 8
    static let pinnedTabsVerticalPadding: CGFloat = 12
    static let pinnedFadeTail: CGFloat = 8
    static let pinnedFadeDuration: TimeInterval = 0.25
    static let sectionEdgeTolerance: CGFloat = 1
    static let scrollDuration: TimeInterval = 0.3
    static let scrollSettleDelay: TimeInterval = 0.4
    static let userScrollThreshold: CGFloat = 4
}

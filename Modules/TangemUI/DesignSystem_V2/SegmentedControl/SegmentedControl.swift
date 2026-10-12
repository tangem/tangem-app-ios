//
//  SegmentedControl.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUIUtils

public struct SegmentedControl<Tag: Hashable>: View, Setupable {
    private let items: [Item]
    @Binding private var selection: Tag

    private var isLoading = false
    private var accessibilityIdentifierFactory: ((Item) -> String?)?

    public init(items: [Item], selection: Binding<Tag>) {
        assert(items.count >= 2, "SegmentedControl is designed for at least two segments")
        self.items = items
        _selection = selection
    }

    /// The cap lives here rather than inside the content because `@ScaledMetric` resolves against
    /// the environment handed *into* the view that declares it: clamping from within the content's
    /// own body would size the labels and leave the track growing without bound.
    public var body: some View {
        SegmentedControlContent(
            items: items,
            selection: $selection,
            isLoading: isLoading,
            accessibilityIdentifierFactory: accessibilityIdentifierFactory
        )
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

/// Equal-width segments leave every label the same slot, so past a point the titles truncate faster
/// than the growth helps anyone.
struct SegmentedControlContent<Tag: Hashable>: View {
    typealias Item = SegmentedControl<Tag>.Item
    typealias Phase = SegmentedControl<Tag>.Phase

    let items: [Item]
    @Binding var selection: Tag
    let isLoading: Bool
    let accessibilityIdentifierFactory: ((Item) -> String?)?

    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric private var itemHeight: CGFloat = 32
    @ScaledMetric private var itemSpacing: CGFloat = 4

    @State private var trackWidth: CGFloat = 0
    @State private var phase: Phase = .idle

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .readGeometry(\.size.width, bindTo: $trackWidth)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            Shimmer()
                .variant(.custom(height: trackHeight))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        } else {
            // Loading tears the gesture down without delivering `onEnded`, so the pill would come
            // back lifted and offset by the abandoned drag.
            track
                .onDisappear(perform: resetInteraction)
        }
    }

    private var track: some View {
        ZStack(alignment: .leading) {
            pill

            labels

            pillDragCatcher

            travelObserver
        }
        .padding(SegmentedControlMetrics.trackPadding)
        .background(Capsule().fill(DesignSystem.Color.bgTransparentPrimary))
    }

    private var pill: some View {
        SegmentSelectionPill(isGlass: isLifted)
            // The lift grows the pill's own frame rather than scaling it. A scaled glass layer
            // magnifies the backdrop it sampled at rest into a smear; at its true size the material
            // re-samples and reads as a lens. The outer frame keeps the layout slot so the growth
            // stays centred on the pill.
            .frame(width: itemWidth * liftScale, height: itemHeight * liftScale)
            .frame(width: itemWidth, height: itemHeight)
            .modifier(
                SelectionPillScale(
                    trigger: selection,
                    peakScaleX: 1.1,
                    phaseDuration: 0.1,
                    isEnabled: stretchesOnTravel
                )
            )
            .offset(x: directional(pillOffset))
            .opacity(hasMeasuredTrack ? 1 : 0)
            .allowsHitTesting(false)
    }

    private var labels: some View {
        HStack(spacing: itemSpacing) {
            ForEach(items) { item in
                SegmentItemView(
                    title: item.title,
                    isSelected: item.id == selection,
                    isPillEngaged: phase.isEngaged,
                    height: itemHeight,
                    onTap: { commit(item.id) }
                )
                .accessibilityIdentifier(accessibilityIdentifierFactory?(item))
            }
        }
        .segmentLens(lensGeometry)
    }

    /// Transparent catcher pinned to the pill: the pill is the only grabbable surface, and the
    /// segment buttons underneath keep every other touch.
    private var pillDragCatcher: some View {
        Color.clear
            .frame(width: itemWidth, height: itemHeight)
            .expandingHitArea(.vertical, by: SegmentedControlMetrics.hitAreaInset)
            .offset(x: directional(pillOffset))
            .gesture(pillDragGesture)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var travelObserver: some View {
        if #unavailable(iOS 17.0) {
            Color.clear
                .frame(width: 0, height: 0)
                .onAnimationCompleted(for: pillOffset) {
                    travelDidArrive()
                }
                .onAnimationCompleted(for: liftScale) {
                    liftDidReachPeak()
                }
                .accessibilityHidden(true)
        }
    }

    private var pillDragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { dragChanged(to: directional($0.translation.width)) }
            .onEnded { commit(settlingTag(for: directional($0.translation.width))) }
    }

    private var dragTranslation: CGFloat? {
        phase.drag
    }

    private var stretchesOnTravel: Bool {
        !usesLens && !reduceMotion
    }

    private var liftsOnPress: Bool {
        usesLens && !reduceMotion
    }

    private var isLifted: Bool {
        liftsOnPress && phase.isEngaged
    }

    private var liftScale: CGFloat {
        isLifted ? SegmentedControlMetrics.pillLiftScale : 1
    }

    private var usesLens: Bool {
        if #available(iOS 26.0, *) {
            return true
        }

        return false
    }
}

// MARK: - Geometry

private extension SegmentedControlContent {
    var hasMeasuredTrack: Bool {
        trackWidth > 0
    }

    /// Mirrors the laid-out track so the loading placeholder keeps the same height at every type size.
    var trackHeight: CGFloat {
        itemHeight + SegmentedControlMetrics.trackPadding * 2
    }

    var slotWidth: CGFloat {
        max(trackWidth - SegmentedControlMetrics.trackPadding * 2, 0)
    }

    var itemWidth: CGFloat {
        guard !items.isEmpty else { return 0 }

        let spacingTotal = itemSpacing * CGFloat(items.count - 1)
        return max((slotWidth - spacingTotal) / CGFloat(items.count), 0)
    }

    var slotStride: CGFloat {
        itemWidth + itemSpacing
    }

    var selectedIndex: Int {
        items.firstIndex { $0.id == selection } ?? 0
    }

    var pillOffset: CGFloat {
        let settled = slotStride * CGFloat(selectedIndex)

        guard let dragTranslation else { return settled }

        return clampedOffset(settled + dragTranslation)
    }

    func clampedOffset(_ offset: CGFloat) -> CGFloat {
        min(max(offset, 0), slotStride * CGFloat(max(items.count - 1, 0)))
    }

    func settlingIndex(for translation: CGFloat) -> Int {
        guard slotStride > 0 else { return selectedIndex }

        let offset = clampedOffset(slotStride * CGFloat(selectedIndex) + translation)
        return Int((offset / slotStride).rounded())
    }

    func settlingTag(for translation: CGFloat) -> Tag {
        let index = settlingIndex(for: translation)

        guard items.indices.contains(index) else { return selection }

        return items[index].id
    }

    func travels(to target: Tag) -> Bool {
        let targetIndex = items.firstIndex { $0.id == target } ?? selectedIndex
        return abs(slotStride * CGFloat(targetIndex) - pillOffset) > SegmentedControlMetrics.travelEpsilon
    }

    func directional(_ value: CGFloat) -> CGFloat {
        layoutDirection == .rightToLeft ? -value : value
    }

    var lensGeometry: SegmentLensGeometry {
        let centerX = pillOffset + itemWidth / 2

        return SegmentLensGeometry(
            center: CGPoint(
                x: layoutDirection == .rightToLeft ? slotWidth - centerX : centerX,
                y: itemHeight / 2
            ),
            restingSize: CGSize(width: itemWidth, height: itemHeight),
            lift: isLifted ? 1 : 0
        )
    }
}

// MARK: - Interaction

private extension SegmentedControlContent {
    var travelAnimation: Animation {
        guard !reduceMotion else {
            return .linear(duration: 0.1)
        }

        let curve: AnimationCurve = usesLens ? .overshootPronounced : .overshootSubtle
        return .curve(curve, duration: 0.2)
    }

    func animate(_ animation: Animation, changes: () -> Void, completion: @escaping () -> Void) {
        if #available(iOS 17.0, *) {
            withAnimation(animation, changes, completion: completion)
        } else {
            withAnimation(animation, changes)
        }
    }

    func dragChanged(to translation: CGFloat) {
        switch phase {
        case .idle:
            animate(SegmentedControlMetrics.pressAnimation) {
                phase = liftsOnPress ? .rising(drag: translation) : .held(drag: translation)
            } completion: {
                liftDidReachPeak()
            }
        case .rising:
            phase = .rising(drag: translation)
        case .held:
            phase = .held(drag: translation)
        case .awaitingPeak, .traveling:
            break
        }
    }

    func commit(_ target: Tag) {
        let isChanged = target != selection

        switch phase {
        case .rising(let drag), .awaitingPeak(_, let drag):
            phase = .awaitingPeak(target: target, drag: drag)
        case .idle:
            liftThenTravel(to: target)
        case .held, .traveling:
            startTravel(to: target)
        }

        if isChanged {
            FeedbackGenerator.selection()
        }
    }

    func liftDidReachPeak() {
        switch phase {
        case .rising(let drag):
            phase = .held(drag: drag)
        case .awaitingPeak(let target, _):
            startTravel(to: target)
        case .idle, .held, .traveling:
            break
        }
    }

    func travelDidArrive() {
        guard case .traveling = phase else { return }

        relax()
    }

    func liftThenTravel(to target: Tag) {
        guard liftsOnPress, travels(to: target) else {
            startTravel(to: target)
            return
        }

        animate(SegmentedControlMetrics.pressAnimation) {
            phase = .awaitingPeak(target: target, drag: nil)
        } completion: {
            liftDidReachPeak()
        }
    }

    func startTravel(to target: Tag) {
        let moves = travels(to: target)
        // Only a real move can carry the lift out to its own end; anything else relaxes right away.
        let ridesLift = liftsOnPress && moves

        animate(moves ? travelAnimation : SegmentedControlMetrics.pressAnimation) {
            selection = target
            phase = ridesLift ? .traveling : .idle
        } completion: {
            travelDidArrive()
        }
    }

    func relax() {
        withAnimation(SegmentedControlMetrics.pressAnimation) { phase = .idle }
    }

    func resetInteraction() {
        phase = .idle
    }
}

// MARK: - Setupable Modifiers

public extension SegmentedControl {
    func loading(_ value: Bool) -> Self {
        map { $0.isLoading = value }
    }

    func accessibilityIdentifier(factory: @escaping (Item) -> String?) -> Self {
        map { $0.accessibilityIdentifierFactory = factory }
    }
}

// MARK: - Metrics

enum SegmentedControlMetrics {
    static let trackPadding: CGFloat = 2
    static let hitAreaInset: CGFloat = 6
    static let pillLiftScale: CGFloat = 1.4
    /// How far off the settled offset still counts as the pill having arrived, in points.
    static let travelEpsilon: CGFloat = 0.5

    /// How far a pixel at the pill's edge is dragged inwards, and how deep into the pill the bend
    /// keeps any strength. Both in points at the lift's peak.
    static let lensRefraction: CGFloat = 8
    static let lensDepth: CGFloat = 14

    static let pressAnimation: Animation = .curve(.easeOutEmphasized, duration: 0.15)
    static let labelCrossfade: Animation = .timingCurve(0.5, 0, 0.5, 1, duration: 0.05)
}

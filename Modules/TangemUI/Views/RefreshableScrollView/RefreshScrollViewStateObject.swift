//
//  RefreshScrollViewStateObject.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemUIUtils
import TangemFoundation

public class RefreshScrollViewStateObject: ObservableObject {
    @Published var state: RefreshState = .idle {
        didSet { print("refreshState", state) }
    }

    @Published var dragging: Bool = false {
        didSet { print("dragging", dragging) }
    }

    @Published var offset: CGPoint = .zero {
        didSet { print("offset", offset) }
    }

    @Published var contentOffset: CGFloat = .zero {
        didSet { print("contentOffset", contentOffset) }
    }

    @Published var geometryInfo: GeometryInfo = .zero {
        didSet { print("geometryInfo", geometryInfo) }
    }

    var correctYOffset: CGFloat {
        let offset = -offset.y // - geometryInfo.safeAreaInsets.top
//        print("correctYOffset", offset)
        return offset.rounded()
    }

    lazy var scrollViewDelegate = DraggingScrollViewDelegate(
        dragging: .init(
            get: { [weak self] in self?.dragging ?? false },
            set: { [weak self] in self?.dragging = $0 })
    )

    let settings: Settings
    private let refreshable: () async -> Void

    private var bag = Set<AnyCancellable>()

    public init(settings: Settings = .init(), refreshable: @escaping () async -> Void) {
        self.settings = settings
        self.refreshable = refreshable

        bind()
    }

    func bind() {
        Publishers
            .CombineLatest($offset, $dragging)
            .withWeakCaptureOf(self)
            .sink { $0.didChange(offset: $1.0, dragging: $1.1) }
            .store(in: &bag)
    }

    func didChange(offset: CGPoint, dragging: Bool) {
        switch state {
        case .idle where correctYOffset > settings.threshold:
            startRefreshing()

        // Offset come back to the top or above
        case .afterRefreshing where !dragging && offset.y.rounded() >= .zero:
            print("Update state to idle")
            state = .idle

        case .refreshing where !dragging:
            print("Stop dragging -> updateContentOffset")
            updateContentOffset()

        case .idle, .refreshing, .afterRefreshing:
            // Do nothing
            break
        }
    }

    func startRefreshing() {
        print("Start refreshing")
        FeedbackGenerator.heavy()

        state = .refreshing(Task {
            await refreshable()
            await stopRefreshing()
        })
    }

    @MainActor
    func stopRefreshing() {
        print("Stop refreshing")

        state = dragging ? .afterRefreshing : .idle
        updateContentOffset()
    }

    func updateContentOffset() {
        let duration: CGFloat = 0.4
        switch state {
        case .idle where contentOffset != .zero, .afterRefreshing where contentOffset != .zero:
            withAnimation(.easeOut(duration: duration)) {
                contentOffset = .zero
            }

        case .refreshing where contentOffset == .zero:
            // Extreme easyOut animation
            withAnimation(.timingCurve(0, 0.5, 0.5, 1, duration: 0.3)) {
                contentOffset = settings.refreshAreaHeight
            }

        default:
            break
        }
    }
}

public extension RefreshScrollViewStateObject {
    enum RefreshState: Hashable {
        case idle
        case refreshing(_ task: Task<Void, Never>)
        case afterRefreshing
    }

    struct Settings {
        public let refreshAreaHeight: CGFloat
        public let thresholdMultiplier: CGFloat

        public init(refreshAreaHeight: CGFloat = 75, thresholdMultiplier: CGFloat = 1.5) {
            self.refreshAreaHeight = refreshAreaHeight
            self.thresholdMultiplier = thresholdMultiplier
        }

        public var threshold: CGFloat { refreshAreaHeight * thresholdMultiplier }
    }
}

final class DraggingScrollViewDelegate: NSObject, UIScrollViewDelegate {
    @Binding var dragging: Bool

    init(dragging: Binding<Bool>) {
        _dragging = dragging
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dragging = true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        dragging = false
    }
}

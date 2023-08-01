//
//  BottomSearchableScrollView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

class BottomSheetStateObject: ObservableObject {
    @Published var searchText: String = ""
    @Published var state: SheetState = .bottom
    @Published var openedPercent: CGFloat = 0.1 {
        didSet {
            print("openedPercent ->>", openedPercent)
        }
    }

    @Published var visibleHeight: CGFloat = 0 {
        didSet {
            print("visibleHeight ->>", visibleHeight)
        }
    }

    @Published var scrollViewIsDragging: Bool = false
    @Published var scrollViewStartDraggingOffset: CGPoint?
    @Published var previousDragTranslation: CGSize = .zero
    @Published var headerSize: CGFloat = 44
    @Published var contentOffset: CGPoint = .zero
    @Published var contentSize: CGSize = .zero

    func contentGestureOnChanged(_ value: ClearDragGestureView.Value, proxy: GeometryProxy) {
        print("scrollViewStartDraggingOffset", scrollViewStartDraggingOffset)

        print("value.translation.height", value.translation.height)
        if value.translation.height < 0 {
            scrollViewStartDraggingOffset = contentOffset
        }

        if let scrollViewStartDraggingOffset,
           scrollViewStartDraggingOffset.y >= .zero {
            withAnimation(nil) {
                scrollViewIsDragging = true
            }
            //                        print("value.translation.height", value.location.y)
            let newHeight = currentHeight(proxy: proxy) - max(0, CGFloat(Int(value.translation.height)))
            updateVisibleHeight(newHeight)
        }
    }

    func contentGestureOnEnded(_ value: ClearDragGestureView.Value, proxy: GeometryProxy) {
        if let scrollViewStartDraggingOffset,
           scrollViewStartDraggingOffset.y >= .zero {
            if visibleHeight < height(for: .top, proxy: proxy) * 0.5 {
                state = .bottom
            }
            updateToState(proxy: proxy)
        }

        withAnimation(nil) {
            scrollViewIsDragging = false
        }

        scrollViewStartDraggingOffset = contentOffset
        print("scrollViewStartDraggingOffset end", scrollViewStartDraggingOffset)
    }

    func dragGestureOnChanged(_ value: DragGesture.Value, proxy: GeometryProxy) {
        //                if !stateObject.isDragging {
        //                    stateObject.isDragging = true
        //                }

        //                let dragValue = value.translation.height - previousDragTranslation.height
        //                let locationChange = value.startLocation.y - value.location.y
        //                print("locationChange", locationChange)
        //                print("gesture.location ->>", value.location)
        //                print("gesture.translation ->>", value.translation)
        //                print("gesture.startLocation ->>", value.startLocation)
        //                withAnimation(.interactiveSpring()) {
        let heightChange = value.translation.height
        print("heightChange ->>", heightChange)

        let newHeight = currentHeight(proxy: proxy) - heightChange
        let maxHeight = proxy.size.height + proxy.safeAreaInsets.top

        if newHeight > maxHeight {
        } else {}
        updateVisibleHeight(newHeight)
        visibleHeight = newHeight // min(newHeight, maxHeight)
        //                }
        //                if locationChange > 0 {
        //                    stateObject.offset += dragValue / 3
        //                } else {
        //                    stateObject.offset += dragValue
        //                }

        //                stateObject.previousDragTranslation = value.translation
    }

    func dragGestureOnEnded(_ value: DragGesture.Value, proxy: GeometryProxy) {
        //        stateObject.previousDragTranslation = .zero
        //        stateObject.isDragging = false

//        print("value.predictedEndLocation ->>", value.predictedEndLocation)
//        print("value.location ->>", value.location)
//        print("value.translation.height ->>", value.translation.height)

        updateSheetFor(predictedEndLocation: value.predictedEndLocation, proxy: proxy)
    }

    func updateSheetFor(
        predictedEndLocation: CGPoint,
        proxy: GeometryProxy
    ) {
        let topAnchorLine = proxy.size.height / 3
        let bottomAnchorLine = proxy.size.height / 3 * 2

        switch predictedEndLocation.y {
        case ...topAnchorLine:
            state = .top
        //                case topAnchorLine ... bottomAnchorLine:
        //                    state = .middle
        case bottomAnchorLine...:
            state = .bottom
        default:
            //            print("Ended location outside screen \(value.location.y)")
            state = .bottom
        }

        updateToState(proxy: proxy)
    }

    func height(for state: SheetState, proxy: GeometryProxy) -> CGFloat {
//        print("proxy.safeAreaInsets ->>", proxy.safeAreaInsets)
//        print("proxy.size ->>", proxy.size)
//        print("proxy.size.frame ->>", proxy.frame(in: .global).size)

        switch state {
        case .bottom:
            return headerSize // + proxy.safeAreaInsets.bottom
        case .top:
            return proxy.size.height + proxy.safeAreaInsets.bottom
        case .hidden:
            return 0
        }
    }

    func updateVisibleHeight(_ height: CGFloat) {
        withAnimation(.interactiveSpring()) {
            visibleHeight = height
        }
    }

    func currentHeight(proxy: GeometryProxy) -> CGFloat {
        height(for: state, proxy: proxy)
    }

    func updateToState(proxy: GeometryProxy) {
        withAnimation(.easeOut) {
            visibleHeight = currentHeight(proxy: proxy)
        }
    }
}

extension BottomSheetStateObject {
    enum SheetState: String, Hashable {
        case top
        //        case middle
        case bottom
        case hidden
    }
}

struct BottomSearchableScrollView<Content: View>: View {
    @ObservedObject private var stateObject: BottomSheetStateObject
    @ViewBuilder private let content: () -> Content

    init(
        stateObject: BottomSheetStateObject = BottomSheetStateObject(),
        content: @escaping () -> Content
    ) {
        self.stateObject = stateObject
        self.content = content
    }

    private let handHeight: CGFloat = 20
    private let indicatorSize = CGSize(width: 32, height: 4)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color.black.opacity(min(stateObject.openedPercent, 0.4))
                    .ignoresSafeArea(.all)

                sheet(proxy: proxy)
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height + proxy.safeAreaInsets.vertical,
                alignment: .bottom
            )
            .ignoresSafeArea(.all, edges: .all)
            .onAppear {
                stateObject.updateToState(proxy: proxy)
            }
        }
    }

    private var indicator: some View {
        ZStack(alignment: .center) {
            Capsule(style: .continuous)
                .fill(Color.gray)
                .frame(width: indicatorSize.width, height: indicatorSize.height)
        }
        .frame(maxWidth: .infinity)
        .frame(height: handHeight)
        .background(Color.purple.opacity(0.5))
    }

    private func headerView(proxy: GeometryProxy) -> some View {
        VStack(spacing: .zero) {
            indicator

            TextField("Placeholder", text: $stateObject.searchText)
                .frame(height: 46)
                .padding(.horizontal)
                .background(Color.secondary.opacity(0.4))
                .cornerRadius(14)
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
        .readGeometry(\.size.height, bindTo: $stateObject.headerSize)
        .gesture(dragGesture(proxy: proxy))
    }

    private func sheet(proxy: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            Color.white

            VStack(spacing: .zero) {
                Spacer(minLength: 0)

                headerView(proxy: proxy)

                scrollView(proxy: proxy)
            }
        }
        .frame(height: stateObject.visibleHeight, alignment: .bottom)
        .cornerRadius(28, corners: [.topLeft, .topRight])
        .border(Color.orange, width: 3)
    }

    private var axes: Axis.Set {
        return stateObject.scrollViewIsDragging ? [] : .vertical
    }

    private func scrollView(proxy: GeometryProxy) -> some View {
        ScrollView(axes, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: .zero) {
                offsetReader

                content()
                    .readGeometry(\.size, bindTo: $stateObject.contentSize)
                    .background(Color.green.opacity(0.2))
            }
            .overlay(contentDragGesture(proxy: proxy))
        }
        .coordinateSpace(name: "ScrollView")
        .onPreferenceChange(OffsetPreferenceKey.self) { point in
            print("point", point)
            stateObject.contentOffset = point
        }
    }

    private func contentDragGesture(proxy: GeometryProxy) -> ClearDragGestureView {
        ClearDragGestureView(
            onChanged: { value in
                stateObject.contentGestureOnChanged(value, proxy: proxy)
            },
            onEnded: { value in
                stateObject.contentGestureOnEnded(value, proxy: proxy)
            }
        )
    }

    private func dragGesture(proxy: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                stateObject.dragGestureOnChanged(value, proxy: proxy)
            }
            .onEnded { value in
                stateObject.dragGestureOnEnded(value, proxy: proxy)
            }
    }

    private var offsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: OffsetPreferenceKey.self,
                    value: proxy.frame(in: .named("ScrollView")).origin
                )
        }
        .frame(height: 0)
    }
}

extension BottomSearchableScrollView {
    struct Constants {
        let contentCoordinateNameSpace = "ScrollViewContent"
    }
}

struct BottomSearchableScrollView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView(
            data: [String](
                repeating: Date().timeIntervalSince1970.description,
                count: 55
            )
        )
    }

    struct ContentView: View {
        let data: [String]
        @State private var percent: CGFloat = 0
        private var object = BottomSheetStateObject()

        init(data: [String]) {
            self.data = data
        }

        var body: some View {
            ZStack(alignment: .bottom) {
                Color.blue.brightness(0.2)
                    .cornerRadius(14)
                    .scaleEffect(min(1, abs(1 - object.openedPercent / 20)))
                    .edgesIgnoringSafeArea(.all)

                BottomSearchableScrollView(stateObject: object) {
                    ForEach(0 ..< data.count, id: \.self) { index in
                        Text(data[index])
                            .font(.title3)
                            .foregroundColor(Color.black.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.all)
                        //                                .background(Color.black.opacity(0.1))

                        Color.black
                            .opacity(0.2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 2)
                    }
                }
            }
            .background(Color.black)
        }
    }
}

/// Contains the gap between the smallest value for the y-coordinate of
/// the frame layer and the content layer.
struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        //        print("OffsetPreferenceKey.value ->>", value)
    }
}

extension EdgeInsets {
    var vertical: CGFloat {
        top + bottom
    }
}

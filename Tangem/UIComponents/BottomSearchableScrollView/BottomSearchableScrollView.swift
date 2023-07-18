//
//  BottomSearchableScrollView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct BottomSearchableScrollView<Header: View, Content: View>: View {
    @Binding var percent: CGFloat {
        didSet {
            print("percent ->>", percent)
        }
    }
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content
    
    @State private var state: SheetState = .bottom {
        didSet {
            print("state ->>", state)
        }
    }

    @State private var visibleHeight: CGFloat = 0 {
        didSet {
            print("visibleHeight ->>", visibleHeight)
            percent = (visibleHeight - headerViewHeight - 34) / 500
        }
    }
    @State private var scrollViewIsDragging: Bool = false
    @State private var scrollViewStartDraggingOffset: CGPoint?
    @State private var previousDragTranslation: CGSize = .zero
    @State private var headerSize: CGFloat = 44
    @State private var contentOffset: CGPoint = .zero
    @State private var contentSize: CGSize = .zero

    private let handHeight: CGFloat = 20
    private let indicatorSize = CGSize(width: 32, height: 4)
    
    private var headerViewHeight: CGFloat {
        headerSize + handHeight
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color.black.opacity(min(percent, 0.4))
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
                updateToState(proxy: proxy)
            }
        }
    }

    func sheet(proxy: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            Color.white
            
            VStack(spacing: .zero) {
                Spacer(minLength: 0)
                
                headerView(proxy: proxy)
                
                scrollView(proxy: proxy)
            }
        }
        .frame(height: visibleHeight, alignment: .bottom)
        .cornerRadius(28, corners: [.topLeft, .topRight])
        .border(Color.orange, width: 3)
    }
    
    func headerView(proxy: GeometryProxy) -> some View {
        VStack(spacing: .zero) {
            indicator
            
            header()
                .padding(.vertical, 8)
                .readGeometry(\.size.height, bindTo: $headerSize)
        }
        .gesture(dragGesture(proxy: proxy))
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

    private var axes: Axis.Set {
        return scrollViewIsDragging ? [] : .vertical
    }
    
    func scrollView(proxy: GeometryProxy) -> some View {
        ScrollView(axes, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: .zero) {
                offsetReader
                
                content()
                    .readGeometry(\.size, bindTo: $contentSize)
                    .background(Color.green.opacity(0.2))
            }
            .overlay(contentDragGesture(proxy: proxy))
        }
        .coordinateSpace(name: "ScrollView")
        .onPreferenceChange(OffsetPreferenceKey.self) { point in
//            print("contentOffset", point)
            contentOffset = point
        }
    }
    
    private func contentDragGesture(proxy: GeometryProxy) -> ClearDragGestureView {
        ClearDragGestureView(onChanged: { value in
//                    print("onChanged", value)
//                    print("value.translation.height", value.translation.height)
            if let scrollViewStartDraggingOffset,
               scrollViewStartDraggingOffset.y > .zero {
                withAnimation(nil) {
                    scrollViewIsDragging = true
                }
//                        print("value.translation.height", value.location.y)
                withAnimation(.interactiveSpring()) {
                    visibleHeight = currentHeight(proxy: proxy) - max(0, CGFloat(Int(value.translation.height)))
                }
            } else {
                scrollViewStartDraggingOffset = contentOffset
            }
            
        }, onEnded: { value in
            if let scrollViewStartDraggingOffset,
               scrollViewStartDraggingOffset.y > .zero {
                if visibleHeight < height(for: .top, proxy: proxy) * 0.5 {
                    state = .bottom
                }
                updateToState(proxy: proxy)
            }

            withAnimation(nil) {
                scrollViewIsDragging = false
            }
            scrollViewStartDraggingOffset = nil
        })
    }
    
    private func dragGesture(proxy: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
//                if !stateObject.isDragging {
//                    stateObject.isDragging = true
//                }

//                let dragValue = value.translation.height - previousDragTranslation.height
//                let locationChange = value.startLocation.y - value.location.y
//                print("locationChange", locationChange)
//                print("gesture.location ->>", value.location)
//                print("gesture.translation ->>", value.translation)
//                print("gesture.startLocation ->>", value.startLocation)
                withAnimation(.interactiveSpring()) {
                    let newHeight = currentHeight(proxy: proxy) - value.translation.height
                    let maxHeight = proxy.size.height + proxy.safeAreaInsets.top
                    visibleHeight = newHeight // min(newHeight, maxHeight)
                }
//                if locationChange > 0 {
//                    stateObject.offset += dragValue / 3
//                } else {
//                    stateObject.offset += dragValue
//                }

//                stateObject.previousDragTranslation = value.translation
            }
            .onEnded { value in
//                stateObject.previousDragTranslation = .zero
//                stateObject.isDragging = false

                print("value.predictedEndLocation ->>", value.predictedEndLocation)
                print("value.location ->>", value.location)
                print("value.translation.height ->>", value.translation.height)

                updateSheetFor(predictedEndLocation: value.predictedEndLocation, proxy: proxy)
            }
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
        print("proxy.safeAreaInsets ->>", proxy.safeAreaInsets)
        print("proxy.size ->>", proxy.size)
        print("proxy.size.frame ->>", proxy.frame(in: .global).size)
        
        switch state {
        case .bottom:
            return headerViewHeight + proxy.safeAreaInsets.bottom
//        case .middle:
//            return proxy.size.height / 2 + proxy.safeAreaInsets.bottom
        case .top:
            return proxy.size.height + proxy.safeAreaInsets.bottom
        case .hidden:
            return 0
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

    var offsetReader: some View {
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
    enum SheetState: String, Hashable {
        case top
//        case middle
        case bottom
        case hidden
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
        @State private var text: String = ""
        @State private var percent: CGFloat = 0

        var body: some View {
            ZStack(alignment: .bottom) {
                Color.blue.brightness(0.2)
                    .cornerRadius(14)
                    .scaleEffect(min(1, abs(1 - percent / 20)))
                    .edgesIgnoringSafeArea(.all)

                BottomSearchableScrollView(percent: $percent) {
                    TextField("Placeholder", text: $text)
                        .frame(height: 46)
                        .padding(.horizontal)
                        .background(Color.secondary.opacity(0.4))
                        .cornerRadius(14)
                        .padding(.horizontal)
                } content: {
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
private struct OffsetPreferenceKey: PreferenceKey {
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

public struct ClearDragGestureView: UIViewRepresentable {
    public let onChanged: (ClearDragGestureView.Value) -> Void
    public let onEnded: (ClearDragGestureView.Value) -> Void

    /// This API is meant to mirror DragGesture,.Value as that has no accessible initializers
    public struct Value {
        /// The time associated with the current event.
        public let time: Date

        /// The location of the current event.
        public let location: CGPoint

        /// The location of the first event.
        public let startLocation: CGPoint

        public let velocity: CGPoint

        /// The total translation from the first event to the current
        /// event. Equivalent to `location.{x,y} -
        /// startLocation.{x,y}`.
        public var translation: CGSize {
            return CGSize(width: location.x - startLocation.x, height: location.y - startLocation.y)
        }

        /// A prediction of where the final location would be if
        /// dragging stopped now, based on the current drag velocity.
        public var predictedEndLocation: CGPoint {
            let endTranslation = predictedEndTranslation
            return CGPoint(x: location.x + endTranslation.width, y: location.y + endTranslation.height)
        }

        public var predictedEndTranslation: CGSize {
            return CGSize(width: estimatedTranslation(fromVelocity: velocity.x), height: estimatedTranslation(fromVelocity: velocity.y))
        }

        private func estimatedTranslation(fromVelocity velocity: CGFloat) -> CGFloat {
            // This is a guess. I couldn't find any documentation anywhere on what this should be
            let acceleration: CGFloat = 500
            let timeToStop = velocity / acceleration
            return velocity * timeToStop / 2
        }
    }

    public class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let onChanged: (ClearDragGestureView.Value) -> Void
        let onEnded: (ClearDragGestureView.Value) -> Void

        private var startLocation = CGPoint.zero

        init(onChanged: @escaping (ClearDragGestureView.Value) -> Void, onEnded: @escaping (ClearDragGestureView.Value) -> Void) {
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        @objc func gestureRecognizerPanned(_ gesture: UIPanGestureRecognizer) {
            guard let view = getGlobalView() else {
                assertionFailure("Missing view on gesture")
                return
            }

            switch gesture.state {
            case .possible, .cancelled, .failed:
                break
            case .began:
                startLocation = gesture.location(in: view)
            case .changed:
                let value = ClearDragGestureView.Value(time: Date(),
                                                       location: gesture.location(in: view),
                                                       startLocation: startLocation,
                                                       velocity: gesture.velocity(in: view))
                onChanged(value)
            case .ended:
                let value = ClearDragGestureView.Value(time: Date(),
                                                       location: gesture.location(in: view),
                                                       startLocation: startLocation,
                                                       velocity: gesture.velocity(in: view))
                onEnded(value)
            @unknown default:
                break
            }
        }
        
        private func getGlobalView() -> UIView? {
            //        getting the all scenes
            let scenes = UIApplication.shared.connectedScenes
            //        getting windowScene from scenes
            let windowScene = scenes.first as? UIWindowScene
            //        getting window from windowScene
            let window = windowScene?.windows.first
            //        getting the root view controller
            let rootVC = window?.rootViewController
            
            return rootVC?.view
        }
    }

    public func makeCoordinator() -> ClearDragGestureView.Coordinator {
        return Coordinator(onChanged: onChanged, onEnded: onEnded)
    }

    public func makeUIView(context: UIViewRepresentableContext<ClearDragGestureView>) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let drag = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.gestureRecognizerPanned))
        drag.delegate = context.coordinator
        view.addGestureRecognizer(drag)

        return view
    }

    public func updateUIView(_ uiView: UIView,
                             context: UIViewRepresentableContext<ClearDragGestureView>) {
    }
}

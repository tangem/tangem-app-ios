// Authoer: The SwiftUI Lab
// Full article: https://swiftui-lab.com/scrollview-pull-to-refresh/
import SwiftUI

typealias RefreshComplete = () -> Void
typealias OnRefresh = (@escaping RefreshComplete) -> Void

struct RefreshableScrollView<Content: View>: View {
    @State private var previousScrollOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var frozen: Bool = false
    @State private var rotation: Angle = .degrees(0)
    @State private var alpha: Double = 0
    @State private var refreshing: Bool = false

    var threshold: CGFloat = 100
    let onRefresh: OnRefresh
    let content: Content

    init(height: CGFloat = 100, onRefresh: @escaping OnRefresh, @ViewBuilder content: () -> Content) {
        self.threshold = height
        self.onRefresh = onRefresh
        self.content = content()
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            refreshableScrollView
        } else if #available(iOS 15.0, *) {
            refreshableList
        } else {
            scrollViewWithHacks
        }
    }

    @available(iOS 16.0, *)
    private var refreshableScrollView: some View {
        ScrollView(.vertical) {
            self.content
        }
        .refreshable {
            await withCheckedContinuation { continuation in
                onRefresh {
                    continuation.resume()
                }
            }
        }
    }

    @available(iOS 15.0, *)
    private var refreshableList: some View {
        List {
            self.content
                .listRowSeparatorTint(.clear)
                .listRowBackground(Color.clear)
                .listRowInsets(.init())
        }
        .listStyle(.plain)
        .refreshable {
            await withCheckedContinuation { continuation in
                onRefresh {
                    continuation.resume()
                }
            }
        }
    }

    private var scrollViewWithHacks: some View {
        return VStack {
            ScrollView {
                ZStack(alignment: .top) {
                    MovingView()

                    VStack { self.content }.alignmentGuide(.top, computeValue: { d in (self.refreshing && self.frozen) ? (-self.threshold + 30) : 0.0 })

                    SymbolView(height: self.threshold - 30, loading: self.refreshing, frozen: self.frozen, rotation: self.rotation, alpha: alpha)
                }
            }
            .background(FixedView())
            .onPreferenceChange(RefreshableKeyTypes.PrefKey.self) { values in
                self.refreshLogic(values: values)
            }
        }
    }

    private func refreshLogic(values: [RefreshableKeyTypes.PrefData]) {
        DispatchQueue.main.async {
            // Calculate scroll offset
            let movingBounds = values.first { $0.vType == .movingView }?.bounds ?? .zero
            let fixedBounds = values.first { $0.vType == .fixedView }?.bounds ?? .zero

            self.scrollOffset  = movingBounds.minY - fixedBounds.minY

            self.rotation = self.symbolRotation(self.scrollOffset)
            self.alpha = self.symbolAlpha(self.scrollOffset)

            // Crossing the threshold on the way down, we start the refresh process
            if !self.refreshing && (self.scrollOffset > self.threshold && self.previousScrollOffset <= self.threshold) {
                self.refreshing = true

                self.onRefresh {
                    self.refreshing = false
                }
            }
            if self.refreshing {
                // Crossing the threshold on the way up, we add a space at the top of the scrollview
                if self.previousScrollOffset > self.threshold && self.scrollOffset < self.previousScrollOffset {
                    frozen = true
                }
            } else {
                // remove the sapce at the top of the scroll view
                self.frozen = false
            }

            // Update last scroll offset
            self.previousScrollOffset = self.scrollOffset
        }
    }

    private func symbolAnimationProgress(_ scrollOffset: CGFloat) -> Double {
        // We will begin rotation, only after we have passed
        // 60% of the way of reaching the threshold.
        let h = Double(self.threshold)
        let d = Double(scrollOffset)
        let v = max(min(d - (h * 0.6), h * 0.4), 0)
        return v / (h * 0.4)
    }

    private func symbolRotation(_ scrollOffset: CGFloat) -> Angle {
        return .degrees(180 * symbolAnimationProgress(scrollOffset))
    }

    private func symbolAlpha(_ scrollOffset: Double) -> Double {
        return symbolAnimationProgress(scrollOffset)
    }

    private struct SymbolView: View {
        var height: CGFloat
        var loading: Bool
        var frozen: Bool
        var rotation: Angle
        var alpha: Double


        var body: some View {
            Group {
                if self.loading { // If loading, show the activity control
                    VStack {
                        Spacer()
                        ActivityRep()
                        Spacer()
                    }.frame(height: height).fixedSize()
                        .offset(y: -height + (self.loading && self.frozen ? height : 0.0))
                } else {
                    Image(systemName: "arrow.down") // If not loading, show the arrow
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: height * 0.25, height: height * 0.25).fixedSize()
                        .padding(height * 0.375)
                        .rotationEffect(rotation)
                        .opacity(alpha)
                        .offset(y: -height + (loading && frozen ? +height : 0.0))
                }
            }
        }
    }

    private struct MovingView: View {
        var body: some View {
            GeometryReader { proxy in
                Color.clear.preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(vType: .movingView, bounds: proxy.frame(in: .global))])
            }.frame(height: 0)
        }
    }

    private struct FixedView: View {
        var body: some View {
            GeometryReader { proxy in
                Color.clear.preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(vType: .fixedView, bounds: proxy.frame(in: .global))])
            }
        }
    }
}

fileprivate struct RefreshableKeyTypes {
    enum ViewType: Int {
        case movingView
        case fixedView
    }

    fileprivate struct PrefData: Equatable {
        let vType: ViewType
        let bounds: CGRect
    }

    fileprivate struct PrefKey: PreferenceKey {
        static var defaultValue: [PrefData] = []

        static func reduce(value: inout [PrefData], nextValue: () -> [PrefData]) {
            value.append(contentsOf: nextValue())
        }

        typealias Value = [PrefData]
    }
}

fileprivate struct ActivityRep: UIViewRepresentable {
    func makeUIView(context: UIViewRepresentableContext<ActivityRep>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView()
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityRep>) {
        if !uiView.isAnimating {
            uiView.startAnimating()
        }
    }
}

struct RefreshableScrollViewView_Previews: PreviewProvider {
    struct _ScrollView: View {
        @State private var text = "123456"

        var body: some View {
            RefreshableScrollView(onRefresh: { completion in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    completion()
                }
            }) {
                VStack {
                    Text("update state").onTapGesture {
                        text = "\(Date())"
                    }

                    Text("Row 1")
                    Text("Row 2")
                    Text("Row 3")
                }

            }
        }
    }

    static var previews: some View {
        _ScrollView()
            .previewDevice("iPhone 11 Pro Max")
    }
}

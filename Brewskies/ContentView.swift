//
//  ContentView.swift
//  Brewskies
//
//  Created by Vipul Delwadia on 10/05/20.
//  Copyright © 2020 Vipul Delwadia. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

struct Brew: Equatable, Identifiable {
    var description = ""
    var isRunning: Bool?
    var date: Date?
    var dose: String?
    var elapsed = 0.0
    var yield: String?

    let id: UUID
}

enum BrewAction {
    case playPauseTapped
    case timerUpdated(TimeInterval)
}

struct BrewEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

let brewReducer = Reducer<Brew, BrewAction, BrewEnvironment> { brew, action, environment in
    struct TimerId: Hashable {}

    switch action {
    case .playPauseTapped:
        brew.isRunning?.toggle()

        switch brew.isRunning {
        case true:
            let start = environment.mainQueue.now

            return Effect.timer(id: TimerId(), every: 0.01, on: environment.mainQueue)
                .map {
                    .timerUpdated(
                        TimeInterval($0.dispatchTime.uptimeNanoseconds - start.dispatchTime.uptimeNanoseconds) / TimeInterval(NSEC_PER_SEC)
                    )
                }
            .cancellable(id: TimerId())

        case false:
            return .cancel(id: TimerId())
        default:
            return .none
        }

    case .timerUpdated(let time):
        brew.elapsed = time
        return .none
    }
}

struct AppState: Equatable {
    var brews: [Brew] = []
    var activeBrews: [Brew] { brews.filter { $0.isRunning != nil } }
    var previousBrews: [Brew] { brews.filter { $0.isRunning == nil } }
}

enum AppAction {
    case brew(index: Int, action: BrewAction)
}

struct AppEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    Reducer { state, action, environment in
        switch action {
        case .brew:
            return .none
        }
    },
    brewReducer.forEach(
        state: \.brews,
        action: /AppAction.brew(index:action:),
        environment: {
            BrewEnvironment(mainQueue: $0.mainQueue)
        }
    )
)

struct ContentView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        NavigationView {
            WithViewStore(self.store) { viewStore in
                List() {
                    Section(header: Text("Current Brews")
                        .font(.headline)
                        .foregroundColor(.primary)
                    ) {
                        ForEachStore(
                            self.store.scope(
                                state: \.activeBrews, action: AppAction.brew(index:action:)
                            ),
                            id: \.id,
                            content: CurrentBrewView.init(store:)
                        )
                    }
                    Section(header: Text("Previous Brews")
                        .font(.headline)
                        .foregroundColor(.primary)
                    ) {
                        ForEachStore(
                            self.store.scope(
                                state: \.previousBrews, action: AppAction.brew(index:action:)
                            ),
                            id: \.id,
                            content: PreviousBrewView.init(store:)
                        )
                    }
                }
                .listStyle(GroupedListStyle())
                .navigationBarTitle("Brews")
                .environment(\.horizontalSizeClass, .regular)
            }
        }
    }
}

struct CurrentBrewView: View {
    @ObservedObject var viewStore: ViewStore<Brew, BrewAction>
    init(store: Store<Brew, BrewAction>) {
        self.viewStore = ViewStore(store)
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack {
                Button(action: { self.viewStore.send(.playPauseTapped) }) {
                    Image(uiImage: UIImage(systemName: self.viewStore.isRunning ?? false ? "pause.fill" : "play.fill")!.withRenderingMode(.alwaysTemplate))
                        .foregroundColor(self.viewStore.isRunning ?? false ? .green : .blue)
//                        .padding()
                    //                .overlay(Circle().stroke(self.viewStore.isRunning ?? false ? Color.green : Color.blue, lineWidth: 4))
                    Text(String(format: "%.2f s", viewStore.elapsed))
                }
                .buttonStyle(PlainButtonStyle())

            }
            .padding(4)


//            Spacer()

            Text(viewStore.description)

//            Spacer()

        }
        .font(Font.system(size: 17).monospacedDigit())
    }
}

struct PreviousBrewView: View {
    @ObservedObject var viewStore: ViewStore<Brew, BrewAction>
    init(store: Store<Brew, BrewAction>) {
        self.viewStore = ViewStore(store)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewStore.description)
                Spacer()
                HStack {
                    Image(systemName: "stopwatch")
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f s", viewStore.elapsed))
                        .font(Font.body.monospacedDigit())
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                viewStore.date.map {
                    Text(relativeFormatter.localizedString(for: $0, relativeTo: Date()))
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                HStack {
                    HStack(spacing: 4) {
                        Text("d")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                            .italic()
                        Text(viewStore.dose ?? "…")
                            .font(Font.body.monospacedDigit())

                    }
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Text("y")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                            .italic()
                        Text(viewStore.yield ?? "…")
                            .font(Font.body.monospacedDigit())
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: Store(
                initialState: AppState(brews: Data.brews),
                reducer: appReducer,
                environment: AppEnvironment(
                    mainQueue: DispatchQueue.main.eraseToAnyScheduler()
                )
            )
        )
            .environment(\.colorScheme, .dark)
    }
}

let isoDateFormatter = ISO8601DateFormatter()
let relativeFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .named
    return formatter
}()


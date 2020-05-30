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
    var dose: Double?
    var elapsed = 0.0
    var yield: Double?

    let id: UUID
}

extension Double {
    var formattedWeight: String? {
        return weightFormatter.string(from: NSNumber(value: self))
    }
}

enum BrewAction: Equatable {
    case playPauseTapped
    case timerUpdated(TimeInterval)
    case descriptionFieldChanged(String)
    case doseFieldChanged(String)
    case yieldFieldChanged(String)
    case saveButtonTapped
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

            return Effect.timer(id: TimerId(), every: 0.1, on: environment.mainQueue)
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

    case .descriptionFieldChanged(let description):
        brew.description = description
        return .none

    case .doseFieldChanged(let text):
        brew.dose = weightFormatter.number(from: text)?.doubleValue
        return .none

    case .yieldFieldChanged(let text):
        brew.yield = weightFormatter.number(from: text)?.doubleValue
        return .none

    case .saveButtonTapped:
        brew.isRunning = nil
        return .none
    }
}

struct AppState: Equatable {
    var brews: IdentifiedArrayOf<Brew> = []
    var activeBrews: IdentifiedArrayOf<Brew> { self.brews.filter { $0.isRunning != nil } }
    var previousBrews: IdentifiedArrayOf<Brew> { self.brews.filter { $0.isRunning == nil } }
}

enum AppAction: Equatable {
    case addButtonTapped
    case brew(id: UUID, action: BrewAction)
}

struct AppEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var uuid: () -> UUID
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    Reducer { state, action, environment in
        switch action {
        case .addButtonTapped:
            state.brews.insert(Brew(isRunning: false, id: environment.uuid()), at: 0)
            return .none
        case .brew:
            return .none
        }
    },
    brewReducer.forEach(
        state: \AppState.brews,
        action: /AppAction.brew(id:action:),
        environment: { BrewEnvironment(mainQueue: $0.mainQueue) }
    )
)

struct AppView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            NavigationView {
                List {
                    Section(header: Text("Current Brew\(viewStore.activeBrews.count != 1 ? "s" : "")")
                        .font(.headline)
                        .foregroundColor(.primary)
                    ) {
                        ForEachStore(
                            self.store.scope(
                                state: { $0.activeBrews },
                                action: AppAction.brew(id:action:)
                            ),
                            content: CurrentBrewView.init(store:)
                        )
                    }
                    Section(header: Text("Previous Brew\(viewStore.previousBrews.count != 1 ? "s" : "")")
                        .font(.headline)
                        .foregroundColor(.primary)
                    ) {
                    ForEachStore(
                        self.store.scope(
                            state: { $0.previousBrews },
                            action: AppAction.brew(id:action:)
                        ),
                        content: PreviousBrewView.init(store:)
                    )
                    }
                }
                .listStyle(GroupedListStyle())
                .navigationBarTitle("Brews")
                .navigationBarItems(trailing: Button(action: {
                    viewStore.send(.addButtonTapped)
                }) {Image(systemName: "plus")})
                    .navigationViewStyle(StackNavigationViewStyle())
                    .environment(\.horizontalSizeClass, .regular)
            }
        }
    }
}

struct CurrentBrewView: View {
//    @ObservedObject var viewStore: ViewStore<Brew, BrewAction>
//    init(store: Store<Brew, BrewAction>) {
//        self.viewStore = ViewStore(store)
//    }
    let store: Store<Brew, BrewAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            HStack(spacing: 12) {
                VStack(alignment: .trailing) {
                    Button(action: { viewStore.send(.playPauseTapped) }) {
                        Image(uiImage: UIImage(systemName: viewStore.isRunning ?? false ? "pause.fill" : "play.fill")!.withRenderingMode(.alwaysTemplate))
                            .foregroundColor(viewStore.isRunning ?? false ? .green : .blue)
                            .padding()
                        // .overlay(Circle().stroke(self.viewStore.isRunning ?? false ? Color.green : Color.blue, lineWidth: 4))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text(String(format: "%.1f s", viewStore.elapsed))
                }
                .frame(minWidth: 57)

                VStack() {
                    TextField(
                        "Description",
                        text: viewStore.binding(
                            get: { $0.description },
                            send: { BrewAction.descriptionFieldChanged($0) }
                        )
                    )
                        .textFieldStyle(RoundedBorderTextFieldStyle())


                    HStack {
                        TextField(
                            "Dose",
                            text: viewStore.binding(
                                get: { $0.dose?.formattedWeight ?? "" },
                                send: { BrewAction.doseFieldChanged($0) }
                            )
                        )
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)

                        Text("g")
                            .foregroundColor(.secondary)

                        Image(systemName: "arrow.right")

                        TextField(
                            "Yield",
                            text: viewStore.binding(
                                get : { $0.yield?.formattedWeight ?? "" },
                                send: { BrewAction.yieldFieldChanged($0) }
                            )
                        )
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)

                        Text("g")
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: { viewStore.send(.saveButtonTapped) }) {
                    Image(systemName: "checkmark.square.fill")
                        .foregroundColor(.blue)
                }.disabled(viewStore.isRunning ?? false)
                    .buttonStyle(PlainButtonStyle())

            }
            .font(Font.system(size: 20).monospacedDigit())
        }
    }
}

struct PreviousBrewView: View {
    let store: Store<Brew, BrewAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            HStack {
                VStack(alignment: .leading) {
                    Text(viewStore.description)
                    Spacer()
                    HStack {
                        Image(systemName: "stopwatch")
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f s", viewStore.elapsed))
                            .font(Font.body.monospacedDigit())
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    viewStore.date.map {
                        Text($0.previousFormat)
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                    HStack {
                        HStack(spacing: 4) {
                            Text("d")
                                .foregroundColor(.secondary)
                                .font(.footnote)
                                .italic()
                            viewStore.dose?.formattedWeight.map {
                                Text($0)
                                    .font(Font.body.monospacedDigit())
                            }
                            Text("g")
                                .foregroundColor(.secondary)

                        }

                        Image(systemName: "arrow.right")

                        HStack(spacing: 4) {
                            Text("y")
                                .foregroundColor(.secondary)
                                .font(.footnote)
                                .italic()
                            viewStore.yield?.formattedWeight.map {
                                Text($0)
                                    .font(Font.body.monospacedDigit())
                            }
                            Text("g")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

extension IdentifiedArray where ID == UUID, Element == Brew {
    static let mock: Self = [
        Brew(
            description: "",
            isRunning: true,
            date: isoDateFormatter.date(from: "2020-05-10T17:00:00+1200"),
            elapsed: 55.5,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        ),
        Brew(
            description: "Havana",
            isRunning: false,
            date: isoDateFormatter.date(from: "2020-05-10T11:00:00+1200"),
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        ),
        Brew(
            description: "Havana",
            date: isoDateFormatter.date(from: "2020-05-10T08:00:00+1200"),
            dose: 18.2,
            elapsed: 25.22,
            yield: 54.6,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        ),
        Brew(
            description: "Havana",
            date: isoDateFormatter.date(from: "2020-05-09T17:00:00+1200"),
            dose: 18.3,
            elapsed: 18.15,
            yield: 57.1,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        ),
        Brew(
            description: "Bomber",
            date: isoDateFormatter.date(from: "2020-05-08T08:00:00+1200"),
            dose: 18.1,
            elapsed: 23.4,
            yield: 55.8,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
        )
    ]
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(
            store: Store(
                initialState: AppState(brews: .mock),
                reducer: appReducer,
                environment: AppEnvironment(
                    mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
                    uuid: UUID.init
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

let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

extension Date {
    var previousFormat: String {
        relativeFormatter.localizedString(for: self, relativeTo: Date()) +
        ", " +
        timeFormatter.string(from: self)
    }
}

let weightFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 1
    return formatter
}()

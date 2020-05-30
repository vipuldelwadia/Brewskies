//
//  BrewskiesTests.swift
//  BrewskiesTests
//
//  Created by Vipul Delwadia on 10/05/20.
//  Copyright © 2020 Vipul Delwadia. All rights reserved.
//
import ComposableArchitecture
import XCTest

@testable import Brewskies

class BrewskiesTests: XCTestCase {
    let scheduler = DispatchQueue.testScheduler

    func testAddBrew() {
        let store = TestStore(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment(
                mainQueue: self.scheduler.eraseToAnyScheduler(),
                uuid: UUID.incrementing
            )
        )

        store.assert(
            .send(.addButtonTapped) {
                $0.brews.insert(
                    Brew(description: "",
                         isRunning: false,
                         id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                    ),
                    at: 0
                )
            }
        )
    }

    func testSaveBrew() {
        let state = AppState(
            brews: [
                Brew(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                ),
                Brew(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
                ),
                Brew(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
                ),
                Brew(
                    isRunning: false,
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
                ),
                Brew(
                    isRunning: true,
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
                ),
                Brew(
                    isRunning: false,
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
                ),
            ]
        )
        let store = TestStore(
            initialState: state,
            reducer: appReducer,
            environment: AppEnvironment(
                mainQueue: self.scheduler.eraseToAnyScheduler(),
                uuid: { fatalError("not implemented") }
            )
        )

        store.assert(
            .send(.brew(id: state.brews[5].id, action: .saveButtonTapped)) {
                $0.brews[5].isRunning = nil
            }
        )
    }
}

extension UUID {
    // A deterministic, auto-incrementing "UUID" generator for testing.
    static var incrementing: () -> UUID {
        var uuid = 0
        return {
            defer { uuid += 1 }
            return UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", uuid))")!
        }
    }
}

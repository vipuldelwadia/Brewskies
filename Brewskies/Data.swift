//
//  Data.swift
//  Brewskies
//
//  Created by Vipul Delwadia on 10/05/20.
//  Copyright © 2020 Vipul Delwadia. All rights reserved.
//

import Foundation

enum Data {
    static var brews = [
        Brew(
            description: "",
            isRunning: true,
            date: isoDateFormatter.date(from: "2020-05-10T17:00:00+1200"),
            id: UUID()
        ),
        Brew(
            description: "Havana",
            isRunning: false,
            date: isoDateFormatter.date(from: "2020-05-10T11:00:00+1200"),
            id: UUID()
        ),
        Brew(
            description: "Havana",
            date: isoDateFormatter.date(from: "2020-05-10T08:00:00+1200"),
            dose: 18.2,
            elapsed: 25.22,
            yield: 54.6,
            id: UUID()
        ),
        Brew(
            description: "Havana",
            date: isoDateFormatter.date(from: "2020-05-09T17:00:00+1200"),
            dose: 18.3,
            elapsed: 18.15,
            yield: 57.1,
            id: UUID()
        ),
        Brew(
            description: "Bomber",
            date: isoDateFormatter.date(from: "2020-05-08T08:00:00+1200"),
            dose: 18.1,
            elapsed: 23.4,
            yield: 55.8,
            id: UUID()
        )
    ]
}

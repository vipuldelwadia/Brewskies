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
            description: "Havana",
            isRunning: true,
            date: isoDateFormatter.date(from: "2020-05-10T17:00:00+1200"),
            dose: "18.2 g",
//            elapsed: 13.2,
            id: UUID()
        ),
        Brew(
            description: "Havana",
            isRunning: false,
            date: isoDateFormatter.date(from: "2020-05-10T11:00:00+1200"),
            dose: "18.1 g",
//            elapsed: 28.3,
            id: UUID()
        ),
        Brew(
            description: "Havana",
            date: isoDateFormatter.date(from: "2020-05-10T08:00:00+1200"),
            dose: "18.2 g",
            elapsed: 25.22,
            yield: "54.6 g",
            id: UUID()
        ),
        Brew(
            description: "Havana",
            date: isoDateFormatter.date(from: "2020-05-09T17:00:00+1200"),
            dose: "18.3 g",
            elapsed: 18.15,
            yield: "57.1 g",
            id: UUID()
        ),
        Brew(
            description: "Bomber",
            date: isoDateFormatter.date(from: "2020-05-08T08:00:00+1200"),
            dose: "18.1 g",
            elapsed: 23.4,
            yield: "55.8 g",
            id: UUID()
        )
    ]
}

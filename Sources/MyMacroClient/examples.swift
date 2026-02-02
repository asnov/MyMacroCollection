//
//  examples.swift
//  MyMacro
//
//  Created by Alex on 02/02/2026.
//

// MARK: withObservationTracking example
import Observation
import Foundation

@Observable
final class Car {
    var name: String = ""
    var needsRepairs: Bool = false
    
    init(name: String, needsRepairs: Bool = false) {
        self.name = name
        self.needsRepairs = needsRepairs
    }
}

@Observable
@MainActor
final class Garage {
    var cars: [Car] = [Car(name: "Toyota"), Car(name: "Ford")]
    func getCarList() -> String {
        cars.reduce("\(cars.count) cars:") { "\($0) \($1.name)(\($1.needsRepairs ? "T" : "F"))," }
    }
    
    func render() {
        withObservationTracking {
            _ = self.cars.count
            for car in self.cars {
                // Thread.sleep(until: .now + 1)
                print("\(car.name)(\(car.needsRepairs))")
            }
        } onChange: {
            print("Schedule renderer.")
            Task { @MainActor in
                self.render()
            }
        }
    }
    
    func changes() -> AsyncStream<String> {
        let base = Observations.tracking {
            _ = self.cars.count
            for car in self.cars {
                _ = car.name
                _ = car.needsRepairs
            }
            return self.getCarList()
        } onChange: {
        }
        return AsyncStream { continuation in
            Task { @MainActor in
                for await snapshot in base {
                    continuation.yield(snapshot)
                }
                continuation.finish()
            }
        }
    }
}

@MainActor let garage = Garage()

@MainActor func examples() async throws {
    Task { @MainActor in
        garage.render()
    }

    Task { @MainActor in
        for await snapshot in garage.changes() {
            print("observations:", snapshot)
        }
    }

    Task { @MainActor in
        print("inside task 1:", garage.getCarList())

        garage.cars[0].name = "BMW" // Schedule renderer.
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("inside task 2:", garage.getCarList())

        garage.cars.append(.init(name: "Nissan"))
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("inside task 3:", garage.getCarList())

        garage.cars[1].name = "Ferrary"
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("inside task 4:", garage.getCarList())

        garage.cars[0].needsRepairs = true
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("inside task 5:", garage.getCarList())
    }

    try await Task.sleep(nanoseconds: 5_000_000_000)
    print("finished:", garage.getCarList())
}

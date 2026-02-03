// The Swift Programming Language
// https://docs.swift.org/swift-book

import Observation

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "MyMacroMacros", type: "StringifyMacro")


@freestanding(expression)
public macro computeSquare(number: Int) -> Int = #externalMacro(module: "MyMacroMacros", type: "ComputeSquareMacro")

@freestanding(declaration, names: named(DecloMacroStruct))
public macro declareStructWithValue<T>(_ value: T) = #externalMacro(module: "MyMacroMacros", type: "DecloMacroExample")

@attached(member, names: arbitrary)
public macro WebsiteGiver() = #externalMacro(module: "MyMacroMacros", type: "EnumMemberMacro")

@attached(accessor, names: named(dict))
public macro StoringGuy() = #externalMacro(module: "MyMacroMacros", type: "StoringGuyMacro")

@attached(memberAttribute)
public macro StoringGuyAttributes() = #externalMacro(module: "MyMacroMacros", type: "StoringGuyMacro")

@attached(peer, names: overloaded)
public macro AddAsync() = #externalMacro(module: "MyMacroMacros", type: "AddAsyncMacro")

/// A macro that generates a logger function to let the
/// object log the issue within but only during debuging. For example,
///
///     @DebugLogger
///     class Foo {}
///
/// `produces a function`
///     func log(issue: String) {
///         #if DEBUG
///         print("In Foo - \(issue)")
///         #endif
///     }
@attached(member, names: named(log(issue:)))
public macro DebugLogger() = #externalMacro(module: "MyMacroMacros", type: "DebugLoggerMacro")


//@attached(member, names: named(_$observationRegistrar), named(access), named(withMutation), named(shouldNotifyObservers))
//@attached(memberAttribute)
//@attached(extension, conformances: Observable) public macro RemoteObservable() = #externalMacro(module: "ObservationMacros", type: "ObservableMacro")

@attached(member, names: named(logStructure))
public macro PrintableStructure() = #externalMacro(module: "MyMacroMacros", type: "PrintableStructureMacro")

// The Swift Programming Language
// https://docs.swift.org/swift-book

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

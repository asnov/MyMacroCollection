import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

import SwiftDiagnostics
/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext,
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct ComputeSquareMacro: ExpressionMacro {
    public static func expansion(
        of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext,
    ) throws -> SwiftSyntax.ExprSyntax {
        guard let argument = node.arguments.first?.expression,
              let literalValue = argument.as(IntegerLiteralExprSyntax.self)?.literal.text,
              let number = Int(literalValue) else {
            throw MacroExpansionErrorMessage("Invalid argument for computeSquare")
        }
        let squaredValue = number * number
        return ExprSyntax(IntegerLiteralExprSyntax(integerLiteral: squaredValue))
    }
}

struct MyMessage: NoteMessage {
    var message: String
    var noteID: SwiftDiagnostics.MessageID
}

struct DecloMacroExample: DeclarationMacro {
    static func expansion(
        of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext,
    ) throws -> [SwiftSyntax.DeclSyntax] {
//        Note(node: node.root, message: MyMessage(message: "qwer", noteID: .init(domain: "domain", id: "id")))
//        MacroExpansionNoteMessage("qwerewq")
        guard let argument = node.arguments.first?.expression else {
            throw MacroExpansionErrorMessage("Wrong argument!")
        }
        return ["""
            struct DecloMacroStruct {
                static let value = \(argument)
            }
            """]
    }
}

public struct EnumMemberMacro: MemberMacro {
    public static func expansion<Declaration: DeclGroupSyntax, Context: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        conformingTo protocols: [TypeSyntax],
        in context: Context,
    ) throws -> [DeclSyntax] {
        let cases = declaration.memberBlock.members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .map { $0.elements.first?.name.text }
            .compactMap { $0 }
            .map {
                """
                case .\($0):
                    return "www.\($0).com"
                """
            }
        let casesString = cases.joined(separator: "\n")
        return ["""
            var website: String {
                switch self {
                    \(raw: casesString)
                }
            }
            """]
    }
}

public struct StoringGuyMacro: AccessorMacro {
    public static func expansion<
        Context: SwiftSyntaxMacros.MacroExpansionContext,
        Declaration: SwiftSyntax.DeclSyntaxProtocol,
    >(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: Declaration,
        in context: Context,
    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
        else {
            return []
        }
        return ["""
            get {
                dict["\(raw: identifier.text)"]! as! String
            }
            """, """
            set {
                dict["\(raw: identifier.text)"] = newValue
            }
            """
        ]
    }
}

extension StoringGuyMacro: MemberAttributeMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AttributeSyntax] {
        guard let property = member.as(VariableDeclSyntax.self),
              !property.description.contains("dict")
        else {
            return []
        }
        
        return [
            AttributeSyntax(
                attributeName: IdentifierTypeSyntax(
                    name: .identifier("StoringGuy")
                )
            )
            .with(\.leadingTrivia, [.newlines(1), .spaces(2)]) // making sure we are on next line after we add @StoringGuy accessory
        ]
    }
}


// from https://github.com/swiftlang/swift-syntax/blob/main/Examples/Sources/MacroExamples/Implementation/Peer/AddAsyncMacro.swift
extension SyntaxCollection {
  mutating func removeLast() {
    self.remove(at: self.index(before: self.endIndex))
  }
}

public struct AddAsyncMacro: PeerMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {

        // Only on functions at the moment.
        guard var funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("@addAsync only works on functions")
        }

        // This only makes sense for non async functions.
        if funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil {
            throw MacroExpansionErrorMessage("@addAsync requires an non async function")
        }

        // This only makes sense void functions
        if let returnClause = funcDecl.signature.returnClause,
           returnClause.type.as(IdentifierTypeSyntax.self)?.name.text != "Void" {
            throw MacroExpansionErrorMessage("@addAsync requires an function that returns void")
        }

        // TODO: check for the presence of @escaping as without it User will see handler absence error which is not correspond
        // Requires a completion handler block as last parameter
        let completionHandlerParameter = funcDecl
            .signature
            .parameterClause
            .parameters.last?
            .type.as(AttributedTypeSyntax.self)?
            .baseType.as(FunctionTypeSyntax.self)
        guard let completionHandlerParameter else {
            throw MacroExpansionErrorMessage("@addAsync requires an function that has a completion handler as last parameter")
        }
        
        // Completion handler needs to return Void
        if completionHandlerParameter.returnClause.type.as(IdentifierTypeSyntax.self)?.name.text != "Void" {
            throw MacroExpansionErrorMessage("@addAsync requires an function that has a completion handler that returns Void")
        }
        
        let returnType = completionHandlerParameter.parameters.first?.type
        
        let isResultReturn = returnType?.children(viewMode: .all).first?.description == "Result"
        let successReturnType: TypeSyntax?
        
        if isResultReturn {
            let argument = returnType!.as(IdentifierTypeSyntax.self)!.genericArgumentClause?.arguments.first!.argument
            
            switch argument {
            case .some(.type(let type)):
                successReturnType = type
                
            case .some(.expr(_)):
                throw MacroExpansionErrorMessage("Found unexpected value generic in Result type")
                
            case .none:
                successReturnType = nil
            }
        } else {
            successReturnType = returnType
        }
        
        // Remove completionHandler and comma from the previous parameter
        var newParameterList = funcDecl.signature.parameterClause.parameters
        newParameterList.removeLast()
        var newParameterListLastParameter = newParameterList.last!
        newParameterList.removeLast()
        newParameterListLastParameter.trailingTrivia = []
        newParameterListLastParameter.trailingComma = nil
        newParameterList.append(newParameterListLastParameter)
        
        // Drop the @addAsync attribute from the new declaration.
        let newAttributeList = funcDecl.attributes.filter {
            guard case let .attribute(attribute) = $0,
                  let attributeType = attribute.attributeName.as(IdentifierTypeSyntax.self),
                  let nodeType = node.attributeName.as(IdentifierTypeSyntax.self)
            else {
                return true
            }
            
            return attributeType.name.text != nodeType.name.text
        }
        
        let callArguments: [String] = newParameterList.map { param in
            let argName = param.secondName ?? param.firstName
            
            let paramName = param.firstName
            if paramName.text != "_" {
                return "\(paramName.text): \(argName.text)"
            }
            
            return "\(argName.text)"
        }
        
        let switchBody: ExprSyntax =
              """
                    switch returnValue {
                    case .success(let value):
                      continuation.resume(returning: value)
                    case .failure(let error):
                      continuation.resume(throwing: error)
                    }
              """
        
        let newBody: ExprSyntax =
              """
                \(raw: isResultReturn ? "try await withCheckedThrowingContinuation { continuation in" : "await withCheckedContinuation { continuation in")
                  \(raw: funcDecl.name)(\(raw: callArguments.joined(separator: ", "))) { \(raw: returnType != nil ? "returnValue in" : "")
              
              \(raw: isResultReturn ? switchBody : "continuation.resume(returning: \(raw: returnType != nil ? "returnValue" : "()"))")
                  }
                }
              """
        
        // add async
        funcDecl.signature.effectSpecifiers = FunctionEffectSpecifiersSyntax(
            leadingTrivia: .space,
            asyncSpecifier: .keyword(.async),
            throwsClause: isResultReturn ? ThrowsClauseSyntax(throwsSpecifier: .keyword(.throws)) : nil
        )
        
        // add result type
        if let successReturnType {
            funcDecl.signature.returnClause = ReturnClauseSyntax(
                leadingTrivia: .space,
                type: successReturnType.with(\.leadingTrivia, .space)
            )
        } else {
            funcDecl.signature.returnClause = nil
        }
        
        // drop completion handler
        funcDecl.signature.parameterClause.parameters = newParameterList
        funcDecl.signature.parameterClause.trailingTrivia = []
        
        funcDecl.body = CodeBlockSyntax(
            leftBrace: .leftBraceToken(leadingTrivia: .space),
            statements: CodeBlockItemListSyntax(
                [CodeBlockItemSyntax(item: .expr(newBody))]
            ),
            rightBrace: .rightBraceToken(leadingTrivia: .newline)
        )
        
        funcDecl.attributes = newAttributeList
        
        funcDecl.leadingTrivia = .newlines(2)
        
        return [DeclSyntax(funcDecl)]
    }
}


@main
struct MyMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        ComputeSquareMacro.self,
        DecloMacroExample.self,
        EnumMemberMacro.self,
        StoringGuyMacro.self,
        AddAsyncMacro.self,
    ]
}

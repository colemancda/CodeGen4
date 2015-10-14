﻿import Sugar
import Sugar.Collections
import Sugar.Linq

public enum CGSwiftCodeGeneratorDialect {
	case Standard
	case Silver
}

public class CGSwiftCodeGenerator : CGCStyleCodeGenerator {

	public init() {
		super.init()
		
		// current as of Elements 8.1 and Swift 1.2
		keywords = ["__abstract", "__await", "__catch", "__event", "__finally", "__inline", "__mapped", "__out", "__partial", "__throw", "__try", "__yield", "__COLUMN__", "__FILE__", "__FUNCTION__", "__LINE__", 
					"as", "associativity", "autoreleasepool", "break", "case", "catch", "class", "continue", "convenience", "default", "defer", "deinit", "didSet", "do", "dynamicType",
					"else", "enum", "extension", "fallthrough", "false", "final", "for", "func", "get", "guard", "if", "import", "in", "infix", "init", "inout", "internal", "is",
					"lazy", "left", "let", "mutating", "nil", "none", "nonmutating", "operator", "optional", "override", "postfix", "precedence", "prefix", "private", "protocol", "public",
					"repeat", "required", "rethrows", "return", "right", "self", "Self", "set", "static", "strong", "struct", "subscript", "super", "switch", "throw", "throws", "true", "try", "Type", "typealias",
					"unowned", "var", "weak", "where", "while", "willSet"].ToList() as! List<String>
	}

	public var Dialect: CGSwiftCodeGeneratorDialect = .Standard
	
	public convenience init(dialect: CGSwiftCodeGeneratorDialect) {
		init()
		Dialect = dialect
	}	

	public override var defaultFileExtension: String { return "swift" }

	override func escapeIdentifier(name: String) -> String {
		return "`\(name)`"
	}

	override func generateImport(imp: CGImport) {
		Append("import ")
		generateIdentifier(imp.Name, alwaysEmitNamespace: true)
		AppendLine()
	}

	override func generateStatementTerminator() {
		AppendLine() // no ; in Swift
	}
	
	//
	// Statements
	//
	
	// in C-styleCG Base class
	/*override func generateBeginEndStatement(statement: CGBeginEndBlockStatement) {
	}*/

	override func generateIfElseStatement(statement: CGIfThenElseStatement) {
		Append("if ")
		generateExpression(statement.Condition)
		AppendLine(" {")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.IfStatement)
		decIndent()
		Append("}")
		if let elseStatement = statement.ElseStatement {
			AppendLine(" else {")
			incIndent()
			generateStatementSkippingOuterBeginEndBlock(elseStatement)
			decIndent()
			AppendLine("}")
		} else {
			AppendLine()
		}
	}

	override func generateForToLoopStatement(statement: CGForToLoopStatement) {
		Append("for var ")
		generateIdentifier(statement.LoopVariableName)
		if let type = statement.LoopVariableType {
			Append(": ")
			generateTypeReference(type)
		}
		Append(" = ")
		generateExpression(statement.StartValue)
		Append("; ")
		
		generateIdentifier(statement.LoopVariableName)
		if statement.Direction == CGLoopDirectionKind.Forward {
			Append(" <= ")
		} else {
			Append(" >= ")
		}
		generateExpression(statement.EndValue)
		Append("; ")

		generateIdentifier(statement.LoopVariableName)
		if statement.Direction == CGLoopDirectionKind.Forward {
			Append("++ ")
		} else {
			Append("-- ")
		}

		AppendLine("{")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("}")
	}

	override func generateForEachLoopStatement(statement: CGForEachLoopStatement) {
		Append("for ")
		generateIdentifier(statement.LoopVariableName)
		Append(" in ")
		generateExpression(statement.Collection)
		AppendLine(" {")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("}")
	}

	override func generateWhileDoLoopStatement(statement: CGWhileDoLoopStatement) {
		Append("while ")
		generateExpression(statement.Condition)
		AppendLine(" {")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		Append("}")
	}

	override func generateDoWhileLoopStatement(statement: CGDoWhileLoopStatement) {
		Append("repeat {")
		incIndent()
		generateStatementsSkippingOuterBeginEndBlock(statement.Statements)
		decIndent()
		Append("} while ")
		generateExpression(statement.Condition)
	}

	/*override func generateInfiniteLoopStatement(statement: CGInfiniteLoopStatement) {
		// handled in base
	}*/

	override func generateSwitchStatement(statement: CGSwitchStatement) {
		Append("switch ")
		generateExpression(statement.Expression)
		AppendLine(" {")
		incIndent()
		for c in statement.Cases {
			Append("case ")
			generateExpression(c.CaseExpression)
			AppendLine(":")
			generateStatementsIndentedUnlessItsASingleBeginEndBlock(c.Statements)
		}
		if let defaultStatements = statement.DefaultCase where defaultStatements.Count > 0 {
			AppendLine("default:")
			generateStatementsIndentedUnlessItsASingleBeginEndBlock(defaultStatements)
		}
		decIndent()
		AppendLine("}")
	}

	override func generateLockingStatement(statement: CGLockingStatement) {
		assert(false, "generateLockingStatement is not supported in Swift")
	}

	override func generateUsingStatement(statement: CGUsingStatement) {
		if Dialect == CGSwiftCodeGeneratorDialect.Silver {
			
			// using isn't really supported. But emit this helpful comment for the benefi of Oxidized code
			Append("/* __using")
			generateIdentifier(statement.Name)
			if let type = statement.`Type` {
				Append(": ")
				generateTypeReference(type)
			} 
			Append(" = ")
			generateExpression(statement.Value)
			AppendLine(" { */")
			
			Append("let ")
			generateIdentifier(statement.Name)
			if let type = statement.`Type` {
				Append(": ")
				generateTypeReference(type)
			} 
			Append(" = ")
			generateExpression(statement.Value)
			AppendLine()

			generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)

			// using isn't really supported.
			AppendLine("/* } */")

		} else {
			assert(false, "generateUsingStatement is not supported in Swift")
		}
	}

	override func generateAutoReleasePoolStatement(statement: CGAutoReleasePoolStatement) {
		AppendLine("autoreleasepool { ")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("}")
	}

	override func generateTryFinallyCatchStatement(statement: CGTryFinallyCatchStatement) {
		if Dialect == CGSwiftCodeGeneratorDialect.Silver {
			AppendLine("__try {")
			incIndent()
			generateStatements(statement.Statements)
			decIndent()
			AppendLine("}")
			if let finallyStatements = statement.FinallyStatements where finallyStatements.Count > 0 {
				AppendLine("__finally {")
				incIndent()
				generateStatements(finallyStatements)
				decIndent()
				AppendLine("}")
			}
			if let catchBlocks = statement.CatchBlocks where catchBlocks.Count > 0 {
				for b in catchBlocks {
					if let type = b.`Type` {
						Append("__catch ")
						generateIdentifier(b.Name)
						Append(": ")
						generateTypeReference(type, ignoreNullability: true)
						AppendLine(" {")
					} else {
						AppendLine("__catch {")
					}
					incIndent()
					generateStatements(b.Statements)
					decIndent()
					AppendLine("}")
				}
			}
			//todo
		} else {
			assert(false, "generateTryFinallyCatchStatement is not supported in Swift, except in Silver")
		}
	}

	/*
	override func generateReturnStatement(statement: CGReturnStatement) {
		// handled in base
	}
	*/

	override func generateThrowStatement(statement: CGThrowStatement) {
		if Dialect == CGSwiftCodeGeneratorDialect.Silver {
			if let value = statement.Exception {
				Append("__throw ")
				generateExpression(value)
				AppendLine()
			} else {
				AppendLine("__throw")
			}
		} else {
			if let value = statement.Exception {
				Append("throw ")
				generateExpression(value)
				AppendLine()
			} else {
				AppendLine("throw")
			}
		}
	}

	/*
	override func generateBreakStatement(statement: CGBreakStatement) {
		// handled in base
	}
	*/

	/*
	override func generateContinueStatement(statement: CGContinueStatement) {
		// handled in base
	}
	*/

	override func generateVariableDeclarationStatement(statement: CGVariableDeclarationStatement) {
		if statement.Constant {
			Append("let ")
		} else {
			Append("var ")
		}
		generateIdentifier(statement.Name)
		if let type = statement.`Type` {
			Append(": ")
			generateTypeReference(type)
		}
		if let value = statement.Value {
			Append(" = ")
			generateExpression(value)
		}
		AppendLine()
		//todo: smartly handle non-nulables w/o a value?
	}

	/*
	override func generateAssignmentStatement(statement: CGAssignmentStatement) {
		// handled in base
	}
	*/

	override func generateConstructorCallStatement(statement: CGConstructorCallStatement) {
		if let callSite = statement.CallSite {
			if let typeReferenceExpression = statement.CallSite as? CGTypeReferenceExpression {
				generateTypeReference(typeReferenceExpression.`Type`, ignoreNullability: true)
			} else {
				generateExpression(callSite)
			}
			Append(".")
		}
		Append("init(")
		if let ctorName = statement.ConstructorName {
			swiftGenerateCallParameters(statement.Parameters, firstParamName: removeWithPrefix(ctorName))
		} else {
			swiftGenerateCallParameters(statement.Parameters)
		}
		Append(")")
		AppendLine()
	}
	
	//
	// Expressions
	//

	/*
	override func generateNamedIdentifierExpression(expression: CGNamedIdentifierExpression) {
		// handled in base
	}
	*/

	/*
	override func generateAssignedExpression(expression: CGAssignedExpression) {
		// handled in base
	}
	*/

	/*
	override func generateSizeOfExpression(expression: CGSizeOfExpression) {
		// handled in base
	}
	*/

	override func generateTypeOfExpression(expression: CGTypeOfExpression) {
		if let typeReferenceExpression = expression.Expression as? CGTypeReferenceExpression {
			generateTypeReference(typeReferenceExpression.`Type`, ignoreNullability: true)
		} else {
			generateExpression(expression.Expression)
		}
		if expression.Expression is CGTypeReferenceExpression {
			Append(".self as! AnyClass")
		} else {
			Append(".dynamicType")
		}
	}

	override func generateDefaultExpression(expression: CGDefaultExpression) {
		Append("default(")
		generateTypeReference(expression.`Type`, ignoreNullability: true)
		Append(")")
	}

	override func generateSelectorExpression(expression: CGSelectorExpression) {
		Append("\"\(expression.Name)\"")
	}

	override func generateTypeCastExpression(cast: CGTypeCastExpression) {
		Append("(")
		generateExpression(cast.Expression)
		Append(" as")
		if !cast.GuaranteedSafe {
			if cast.ThrowsException {
				Append("!")
			} else{
				Append("?")
			}
		}
		Append(" ")
		generateTypeReference(cast.TargetType, ignoreNullability: true)
		Append(")")
	}

	override func generateInheritedExpression(expression: CGInheritedExpression) {
		Append("super")
	}

	override func generateSelfExpression(expression: CGSelfExpression) {
		Append("self")
	}

	override func generateNilExpression(expression: CGNilExpression) {
		Append("nil")
	}

	override func generatePropertyValueExpression(expression: CGPropertyValueExpression) {
		Append("newValue")
	}

	override func generateAwaitExpression(expression: CGAwaitExpression) {
		if Dialect == CGSwiftCodeGeneratorDialect.Silver {
			Append("__await ")
			generateExpression(expression.Expression)
		} else {
			assert(false, "generateEventDefinition is not supported in Swift, except in Silver")
		}
	}

	override func generateAnonymousMethodExpression(method: CGAnonymousMethodExpression) {
		Append("{")
		if method.Parameters.Count > 0 {
			Append(" (")
			helpGenerateCommaSeparatedList(method.Parameters) { param in
				self.generateIdentifier(param.Name)
				if let type = param.`Type` {
					self.Append(": ")
					self.generateTypeReference(type)
				}
			}
			Append(") in")
		}
		AppendLine()
		incIndent()
		generateStatements(method.LocalVariables)
		generateStatementsSkippingOuterBeginEndBlock(method.Statements)
		decIndent()
		Append("}")
	}

	override func generateAnonymousTypeExpression(type: CGAnonymousTypeExpression) {
		Append("class ")
		if let ancestor = type.Ancestor {
			generateTypeReference(ancestor, ignoreNullability: true)
			Append(" ")
		}
		AppendLine("{")
		incIndent()
		helpGenerateCommaSeparatedList(type.Members, separator: { self.AppendLine() }) { m in
			
			if let member = m as? CGAnonymousPropertyMemberDefinition {
				
				self.Append("var ")
				self.generateIdentifier(m.Name)
				self.Append(" = ")
				self.generateExpression(member.Value)
				self.AppendLine()
				
			} else if let member = m as? CGAnonymousMethodMemberDefinition {

				self.Append("func ")
				self.generateIdentifier(m.Name)
				self.Append("(")
				self.swiftGenerateDefinitionParameters(member.Parameters)
				self.Append(")")
				if let returnType = member.ReturnType {
					self.Append(" -> ")
					self.generateTypeReference(returnType)
					self.Append(" ")
				}
				self.AppendLine(" {")
				self.incIndent()
				self.generateStatements(member.Statements)
				self.decIndent()
				self.AppendLine("}")
			}
		}
		decIndent()
		Append("}")
	}

	override func generatePointerDereferenceExpression(expression: CGPointerDereferenceExpression) {
		//todo
	}

	/*
	override func generateUnaryOperatorExpression(expression: CGUnaryOperatorExpression) {
		// handled in base
	}
	*/

	/*
	override func generateBinaryOperatorExpression(expression: CGBinaryOperatorExpression) {
		// handled in base
	}
	*/

	/*
	override func generateUnaryOperator(`operator`: CGUnaryOperatorKind) {
		// handled in base
	}
	*/

	override func generateBinaryOperator(`operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .Is: Append("is")
			case .AddEvent: Append("+=") // Silver only
			case .RemoveEvent: Append("-=") // Silver only
			default: super.generateBinaryOperator(`operator`)
		}
	}

	/*
	override func generateIfThenElseExpression(expression: CGIfThenElseExpression) {
		// handled in base
	}
	*/

	/*
	override func generateArrayElementAccessExpression(expression: CGArrayElementAccessExpression) {
		// handled in base
	}
	*/

	internal func swiftGenerateStorageModifierPrefix(type: CGTypeReference?) {
		if let type = type {
			switch type.StorageModifier {
				case .Strong: break
				case .Weak: Append("weak ")
				case .Unretained: Append("unowned ")
			}
		}
	}

	internal func swiftGenerateCallSiteForExpression(expression: CGMemberAccessExpression) {
		if let callSite = expression.CallSite {
			if let typeReferenceExpression = expression.CallSite as? CGTypeReferenceExpression {
				generateTypeReference(typeReferenceExpression.`Type`, ignoreNullability: true)
			} else {
				generateExpression(callSite)
			}
			if expression.NilSafe {
				Append("?")
			} else if expression.UnwrapNullable {
				Append("!")
			}
			Append(".")
		}
	}

	func swiftGenerateCallParameters(parameters: List<CGCallParameter>, firstParamName: String? = nil) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			if let name = param.Name {
				generateIdentifier(name)
				Append(": ")
			} else if p == 0, let name = firstParamName {
				generateIdentifier(name)
				Append(": ")
			}
			switch param.Modifier {
				case .Out: fallthrough
				case .Var: 
					Append("&(")
					generateExpression(param.Value)
					Append(")")
				default: 
					generateExpression(param.Value)
			}
		}
	}

	func swiftGenerateAttributeParameters(parameters: List<CGCallParameter>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			if let name = param.Name {
				generateIdentifier(name)
				Append(" = ")
			}
			generateExpression(param.Value)
		}
	}

	override func generateParameterDefinition(param: CGParameterDefinition) {
		swiftGenerateParameterDefinition(param, emitExternal: false, first: true, firstExternalName: nil) // never emit the _
	}
	
	private func swiftGenerateParameterDefinition(param: CGParameterDefinition, emitExternal: Boolean, first: Boolean, firstExternalName: String? = nil) {
		switch param.Modifier {
			case .Out: 
				if Dialect == CGSwiftCodeGeneratorDialect.Silver {
					Append("__out ")
				} else {
					fallthrough
				}
			case .Var: 
				Append("inout ")
			default: 
		}
		if emitExternal, let externalName = param.ExternalName {
			generateIdentifier(externalName)
			Append(" ")
		} else if first, let externalName = firstExternalName {
			generateIdentifier(externalName)
			Append(" ")
		} else if emitExternal && !first {
			Append("_ ")
		}
		generateIdentifier(param.Name)
		Append(": ")
		generateTypeReference(param.`Type`)
		if let defaultValue = param.DefaultValue {
			Append(" = ")
			generateExpression(defaultValue)
		}
	}

	func swiftGenerateDefinitionParameters(parameters: List<CGParameterDefinition>, firstExternalName: String? = nil) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			} 
			param.startLocation = currentLocation
			swiftGenerateParameterDefinition(param, emitExternal: true, first: p == 0, firstExternalName: firstExternalName)
			param.endLocation = currentLocation
		}
	}

	func swiftGenerateGenericParameters(parameters: List<CGGenericParameterDefinition>?) {
		if let parameters = parameters where parameters.Count > 0 {
			Append("<")
			helpGenerateCommaSeparatedList(parameters) { param in
				self.generateIdentifier(param.Name)
				// variance isn't supported in swift
				//todo: 72081: Silver: NRE in "if let"
				//if let constraints = param.Constraints, filteredConstraints = constraints.Where({ return $0 is CGGenericIsSpecificTypeConstraint}).ToList() where filteredConstraints.Count > 0 {
				if let constraints = param.Constraints where constraints.Count > 0 {
					let filteredConstraints = constraints.Where({ return $0 is CGGenericIsSpecificTypeConstraint})
					self.Append(": ")
					self.helpGenerateCommaSeparatedList(filteredConstraints) { constraint in
						if let constraint2 = constraint as? CGGenericIsSpecificTypeConstraint {
							self.generateTypeReference(constraint2.`Type`)
						}
						// other constraints aren't supported in Swift
					}
				}
			}
			Append(">")
		}
	}

	func swiftGenerateAncestorList(type: CGClassOrStructTypeDefinition) {
		if type.Ancestors.Count > 0 || type.ImplementedInterfaces.Count > 0 {
			Append(" : ")
			var needsComma = false
			for ancestor in type.Ancestors {
				if needsComma {
					Append(", ")
				}
				generateTypeReference(ancestor, ignoreNullability: true)
				needsComma = true
			}
			for interface in type.ImplementedInterfaces {
				if needsComma {
					Append(", ")
				}
				generateTypeReference(interface, ignoreNullability: true)
				needsComma = true
			}
		}
	}

	override func generateFieldAccessExpression(expression: CGFieldAccessExpression) {
		swiftGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
	}

	/*
	override func generateArrayElementAccessExpression(expression: CGArrayElementAccessExpression) {
		// handled in base
	}
	*/

	override func generateMethodCallExpression(expression: CGMethodCallExpression) {
		swiftGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
		if expression.CallOptionally {
			Append("?")
		}
		Append("(")
		swiftGenerateCallParameters(expression.Parameters)		
		Append(")")
	}
	
	override func generateNewInstanceExpression(expression: CGNewInstanceExpression) {
		generateTypeReference(expression.`Type`, ignoreNullability: true)
		if let bounds = expression.ArrayBounds where bounds.Count > 0 {
			Append("[](count: ")
			helpGenerateCommaSeparatedList(bounds) { boundExpression in 
				self.generateExpression(boundExpression)
			}
			Append(")")
		} else {
			Append("(")
			if let name = expression.ConstructorName {
				generateIdentifier(removeWithPrefix(name))
				Append(": ")
			}
			swiftGenerateCallParameters(expression.Parameters)
			Append(")")
		}
	}

	override func generatePropertyAccessExpression(expression: CGPropertyAccessExpression) {
		swiftGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
		if let params = expression.Parameters where params.Count > 0 {
			Append("[")
			swiftGenerateCallParameters(expression.Parameters)
			Append("]")
		}
	}
	
	override func cStyleEscapeSequenceForCharacter(ch: Char) -> String {
		return "\\u{"+Sugar.Cryptography.Utils.ToHexString(Integer(ch), 4)
	}

	/*
	override func generateStringLiteralExpression(expression: CGStringLiteralExpression) {
		// handled in base
	}
	*/

	override func generateCharacterLiteralExpression(expression: CGCharacterLiteralExpression) {
		// Swift uses " and not ', even for chars.
		Append("\"\(cStyleEscapeCharactersInStringLiteral(expression.Value.ToString()))\"")
	}

	override func generateArrayLiteralExpression(array: CGArrayLiteralExpression) {
		Append("[")
		for var e = 0; e < array.Elements.Count; e++ {
			if e > 0 {
				Append(", ")
			}
			generateExpression(array.Elements[e])
		}
		Append("]")
	}

	override func generateDictionaryExpression(dictionary: CGDictionaryLiteralExpression) {
		assert(dictionary.Keys.Count == dictionary.Values.Count, "Number of keys and values in Dictionary doesn't match.")
		Append("[")
		for var e = 0; e < dictionary.Keys.Count; e++ {
			if e > 0 {
				Append(", ")
			}
			generateExpression(dictionary.Keys[e])
			Append(": ")
			generateExpression(dictionary.Values[e])
		}
		Append("]")
	}

	/*
	override func generateTupleExpression(expression: CGTupleLiteralExpression) {
		// default handled in base
	}
	*/
	
	//
	// Type Definitions
	//
	
	override func generateAttribute(attribute: CGAttribute) {
		Append("@")
		generateTypeReference(attribute.`Type`, ignoreNullability: true)
		if let parameters = attribute.Parameters where parameters.Count > 0 {
			Append("(")
			swiftGenerateAttributeParameters(parameters)
			Append(")")
		}   
		AppendLine()	 
	}
	
	func swiftGenerateTypeVisibilityPrefix(visibility: CGTypeVisibilityKind) {
		switch visibility {
			case .Unspecified: break /* no-op */
			case .Unit: Append("internal ")
			case .Assembly: Append("internal ")
			case .Public: Append("public ")
		}
	}
	
	func swiftGenerateMemberTypeVisibilityPrefix(visibility: CGMemberVisibilityKind) {
		switch visibility {
			case .Unspecified: break /* no-op */
			case .Private: Append("private ")
			case .Unit: fallthrough
			case .UnitOrProtected: fallthrough
			case .UnitAndProtected: fallthrough
			case .Assembly: fallthrough
			case .AssemblyAndProtected: Append("internal ")
			case .AssemblyOrProtected: fallthrough
			case .Protected: fallthrough
			case .Published: fallthrough
			case .Public: Append("public ")
		}
	}
	
	func swiftGenerateStaticPrefix(isStatic: Boolean) {
		if isStatic {
			Append("static ")
		}
	}
	
	func swiftGenerateAbstractPrefix(isAbstract: Boolean) {
		if isAbstract && Dialect == CGSwiftCodeGeneratorDialect.Silver {
			Append("__abstract ")
		}
	}

	func swiftGenerateSealedPrefix(isSealed: Boolean) {
		if isSealed {
			Append("final ")
		}
	}

	func swiftGenerateVirtualityPrefix(member: CGMemberDefinition) {
		switch member.Virtuality {
			//case .None
			//case .Virtual
			case .Abstract: if Dialect == CGSwiftCodeGeneratorDialect.Silver { Append("__abstract ") }
			case .Override: Append("override ")
			case .Final: Append("final ")
			//case Reintroduce
			default:
		}
	}

	override func generateAliasType(type: CGTypeAliasDefinition) {
		swiftGenerateTypeVisibilityPrefix(type.Visibility)
		Append("typealias ")
		generateIdentifier(type.Name)
		Append(" = ")
		generateTypeReference(type.ActualType)
		AppendLine()
	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		swiftGenerateTypeVisibilityPrefix(type.Visibility)
		Append("typealias ")
		generateIdentifier(type.Name)
		Append(" = ")
		swiftGenerateInlineBlockType(type)
		AppendLine()
	}
	
	func swiftGenerateInlineBlockType(block: CGBlockTypeDefinition) {
		Append("(")
		for var p: Int32 = 0; p < block.Parameters.Count; p++ {
			if p > 0 {
				Append(", ")
			}
			if let type = block.Parameters[p].`Type` {
				generateTypeReference(type)
			} else {
				Append("Any?")
			}
		}
		Append(") -> ")
		if let returnType = block.ReturnType {
			generateTypeReference(returnType)
		} else {
			Append("()")
		}
	}
	
	override func generateEnumType(type: CGEnumTypeDefinition) {
		swiftGenerateTypeVisibilityPrefix(type.Visibility)
		Append("enum ")
		generateIdentifier(type.Name)
		//ToDo: generic constraints
		if let baseType = type.BaseType {
			Append(" : ")
			generateTypeReference(baseType, ignoreNullability: true)
		}
		AppendLine(" { ")
		incIndent()
		for m in type.Members {
			if let m = m as? CGEnumValueDefinition {
				Append("case ")
				generateIdentifier(m.Name)
				if let value = m.Value {
					Append(" = ")
					generateExpression(value)
				}
				AppendLine()
			}
		}
		decIndent()
		AppendLine("}")
	}
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {
		swiftGenerateTypeVisibilityPrefix(type.Visibility)
		swiftGenerateStaticPrefix(type.Static)
		swiftGenerateAbstractPrefix(type.Abstract)
		swiftGenerateSealedPrefix(type.Sealed)
		Append("class ")
		generateIdentifier(type.Name)
		swiftGenerateGenericParameters(type.GenericParameters)
		swiftGenerateAncestorList(type)
		AppendLine(" { ")
		incIndent()
	}
	
	override func generateClassTypeEnd(type: CGClassTypeDefinition) {
		decIndent()
		AppendLine("}")
	}
	
	override func generateStructTypeStart(type: CGStructTypeDefinition) {
		swiftGenerateTypeVisibilityPrefix(type.Visibility)
		swiftGenerateStaticPrefix(type.Static)
		swiftGenerateAbstractPrefix(type.Abstract)
		swiftGenerateSealedPrefix(type.Sealed)
		Append("struct ")
		generateIdentifier(type.Name)
		swiftGenerateGenericParameters(type.GenericParameters)
		swiftGenerateAncestorList(type)
		AppendLine(" { ")
		incIndent()
	}
	
	override func generateStructTypeEnd(type: CGStructTypeDefinition) {
		decIndent()
		AppendLine("}")
	}		
	
	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {
		swiftGenerateTypeVisibilityPrefix(type.Visibility)
		swiftGenerateSealedPrefix(type.Sealed)
		Append("protocol ")
		generateIdentifier(type.Name)
		swiftGenerateGenericParameters(type.GenericParameters)
		swiftGenerateAncestorList(type)
		AppendLine(" { ")
		incIndent()
	}
	
	override func generateInterfaceTypeEnd(type: CGInterfaceTypeDefinition) {
		decIndent()
		AppendLine("}")
	}	
	
	override func generateExtensionTypeStart(type: CGExtensionTypeDefinition) {
		swiftGenerateTypeVisibilityPrefix(type.Visibility)
		Append("extension ")
		generateIdentifier(type.Name)
		Append(" ")
		AppendLine("{ ")
		incIndent()
	}
	
	override func generateExtensionTypeEnd(type: CGExtensionTypeDefinition) {
		decIndent()
		AppendLine("}")
	}	

	//
	// Type Members
	//
	
	override func generateMethodDefinition(method: CGMethodDefinition, type: CGTypeDefinition) {

		if type is CGInterfaceTypeDefinition {
			swiftGenerateStaticPrefix(method.Static && !type.Static)
		} else {
			swiftGenerateMemberTypeVisibilityPrefix(method.Visibility)
			swiftGenerateStaticPrefix(method.Static && !type.Static)
			swiftGenerateVirtualityPrefix(method)
			if method.External && Dialect == CGSwiftCodeGeneratorDialect.Silver {
				Append("__extern ")
			}
		}
		Append("func ")
		generateIdentifier(method.Name)
		swiftGenerateGenericParameters(method.GenericParameters)
		Append("(")
		swiftGenerateDefinitionParameters(method.Parameters)
		Append(")")
		
		if let returnType = method.ReturnType {
			Append(" -> ")
			returnType.startLocation = currentLocation
			generateTypeReference(returnType)
			returnType.endLocation = currentLocation
		}
		
		if method.Throws {
			Append(" throws")
		}
		
		if type is CGInterfaceTypeDefinition || method.External || definitionOnly {
			AppendLine()
			return
		}
		
		AppendLine(" {")
		incIndent()
		generateStatements(method.LocalVariables)
		generateStatements(method.Statements)
		decIndent()
		AppendLine("}")
	}
	
	override func generateConstructorDefinition(ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		if type is CGInterfaceTypeDefinition {
		} else {
			swiftGenerateMemberTypeVisibilityPrefix(ctor.Visibility)
			swiftGenerateVirtualityPrefix(ctor)
		}
		Append("init(")
		if length(ctor.Name) > 0 {
			swiftGenerateDefinitionParameters(ctor.Parameters, firstExternalName: removeWithPrefix(ctor.Name))
		} else {
			swiftGenerateDefinitionParameters(ctor.Parameters, firstExternalName: "_")
		}
		Append(")")

		if type is CGInterfaceTypeDefinition || definitionOnly {
			AppendLine()
			return
		}

		AppendLine(" {")
		incIndent()
		generateStatements(ctor.LocalVariables)
		generateStatements(ctor.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateDestructorDefinition(dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		Append("deinit")

		if type is CGInterfaceTypeDefinition || definitionOnly {
			AppendLine()
			return
		}

		AppendLine(" {")
		incIndent()
		generateStatements(dtor.LocalVariables)
		generateStatements(dtor.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateFinalizerDefinition(finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		if type is CGInterfaceTypeDefinition {
			swiftGenerateStaticPrefix(finalizer.Static && !type.Static)
		} else {
			swiftGenerateMemberTypeVisibilityPrefix(finalizer.Visibility)
			swiftGenerateStaticPrefix(finalizer.Static && !type.Static)
			swiftGenerateVirtualityPrefix(finalizer)
			if finalizer.External && Dialect == CGSwiftCodeGeneratorDialect.Silver {
				Append("__extern ")
			}
		}
		Append("func Finalizer()")
		
		if type is CGInterfaceTypeDefinition || finalizer.External || definitionOnly {
			AppendLine()
			return
		}
		
		AppendLine(" {")
		incIndent()
		generateStatements(finalizer.LocalVariables)
		generateStatements(finalizer.Statements)
		decIndent()
		AppendLine("}")	
	}

	override func generateFieldDefinition(field: CGFieldDefinition, type: CGTypeDefinition) {
		swiftGenerateMemberTypeVisibilityPrefix(field.Visibility)
		swiftGenerateStaticPrefix(field.Static && !type.Static)
		swiftGenerateStorageModifierPrefix(field.`Type`)
		if field.Constant {
			Append("let ")
		} else {
			Append("var ")
		}
		generateIdentifier(field.Name)
		if let type = field.`Type` {
			Append(": ")
			generateTypeReference(type)
		}
		if let value = field.Initializer {
			Append(" = ")
			generateExpression(value)
		} else {
			swiftGenerateDefaultInitializerForType(field.`Type`)
		}
		AppendLine()
	}

	override func generatePropertyDefinition(property: CGPropertyDefinition, type: CGTypeDefinition) {
		swiftGenerateMemberTypeVisibilityPrefix(property.Visibility)
		swiftGenerateStaticPrefix(property.Static && !type.Static)
		swiftGenerateVirtualityPrefix(property)
		if property.Lazy {
			Append("lazy ")
		}
		swiftGenerateStorageModifierPrefix(property.`Type`)
		
		if let params = property.Parameters where params.Count > 0 {
			
			Append("subscript ")
			generateIdentifier(property.Name)
			Append("(")
			swiftGenerateDefinitionParameters(params)
			Append(")")
			if let type = property.`Type` {
				Append(" -> ")
				generateTypeReference(type)
			} else {
				assert(false, "Swift Subscripts must have a well-defined type.")
			}
			assert(property.Initializer == nil, "Swift Subscripts cannot have an initializer.")
			
		} else {
			
			if property.ReadOnly && (property.IsShortcutProperty) {
				Append("let ")
			} else if property.WriteOnly {
				Append("private(set) var ")
			} else {
				Append("var ")
			}
			generateIdentifier(property.Name)
			if let type = property.`Type` {
				Append(": ")
				generateTypeReference(type)
			}
		}

		if property.IsShortcutProperty {
		
			if let value = property.Initializer {
				Append(" = ")
				generateExpression(value)
			} else {
				swiftGenerateDefaultInitializerForType(property.`Type`)
			}
			AppendLine()
			
		} else {
			
			if let value = property.Initializer {
				assert(false, "Swift Properties cannot have both accessor statements and an initializer")
			}
			
			if type is CGInterfaceTypeDefinition || definitionOnly {
				return
			}

			AppendLine(" {")
			incIndent()
			
			if let getStatements = property.GetStatements {
				AppendLine("get {")
				incIndent()
				generateStatementsSkippingOuterBeginEndBlock(getStatements)
				decIndent()
				AppendLine("}")
			} else if let getExpresssion = property.GetExpression {
				AppendLine("get {")
				incIndent()
				generateStatement(CGReturnStatement(getExpresssion))
				decIndent()
				AppendLine("}")
			}
			
			if let setStatements = property.SetStatements {
				AppendLine("set {")
				incIndent()
				generateStatementsSkippingOuterBeginEndBlock(setStatements)
				decIndent()
				AppendLine("}")
			} else if let setExpression = property.SetExpression {
				AppendLine("set {")
				incIndent()
				generateStatement(CGAssignmentStatement(setExpression, CGPropertyValueExpression.PropertyValue))
				decIndent()
				AppendLine("}")
			}
			
			decIndent()
			AppendLine("}")
		}
	}

	override func generateEventDefinition(event: CGEventDefinition, type: CGTypeDefinition) {
		if Dialect == CGSwiftCodeGeneratorDialect.Silver {
			swiftGenerateMemberTypeVisibilityPrefix(event.Visibility)
			swiftGenerateStaticPrefix(event.Static && !type.Static)
			Append("__event")
			generateIdentifier(event.Name)
			if let type = event.`Type` {
				Append(": ")
				generateTypeReference(type)
			}

			if type is CGInterfaceTypeDefinition || definitionOnly {
				return
			}

			// Todo: Add/Rmeove/raise statements?
		} else {
			assert(false, "generateEventDefinition is not supported in Swift, except in Silver")
		}
	}

	override func generateCustomOperatorDefinition(customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {
		//todo
	}

	override func generateNestedTypeDefinition(member: CGNestedTypeDefinition, type: CGTypeDefinition) {
		generateTypeDefinition(member.`Type`)
	}

	//
	// Type References
	//

	func swiftSuffixForNullability(nullability: CGTypeNullabilityKind, defaultNullability: CGTypeNullabilityKind) -> String {
		switch nullability {
			case .Unknown:
				if Dialect == CGSwiftCodeGeneratorDialect.Silver {
					return "¡"
				} else {
					return ""
				}
			case .NullableUnwrapped:
				return "!"
			case .NullableNotUnwrapped:
				return "?"
			case .NotNullable:
				return ""
			case .Default:
				return swiftSuffixForNullability(defaultNullability, defaultNullability:CGTypeNullabilityKind.Unknown)
		}
	}
	
	func swiftSuffixForNullabilityForCollectionType(type: CGTypeReference) -> String {
		return swiftSuffixForNullability(type.Nullability, defaultNullability: Dialect == CGSwiftCodeGeneratorDialect.Silver ? CGTypeNullabilityKind.NotNullable : CGTypeNullabilityKind.NullableUnwrapped)
	}
	
	func swiftGenerateDefaultInitializerForType(type: CGTypeReference?) {
		if let type = type {
			if type.ActualNullability == CGTypeNullabilityKind.NotNullable || (type.Nullability == CGTypeNullabilityKind.Default && !type.IsClassType) {
				if let defaultValue = type.DefaultValue {
					Append(" = ")
					generateExpression(defaultValue)
				}
			}
		}
	}
	
	override func generateNamedTypeReference(type: CGNamedTypeReference, ignoreNullability: Boolean = false) {
		super.generateNamedTypeReference(type, ignoreNullability: ignoreNullability)
		if !ignoreNullability {
			Append(swiftSuffixForNullability(type.Nullability, defaultNullability: type.DefaultNullability))
		}
	}
	
	override func generatePredefinedTypeReference(type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch (type.Kind) {
			case .Int: Append("Int")
			case .UInt: Append("UInt")
			case .Int8: Append("Int8")
			case .UInt8: Append("UInt8")
			case .Int16: Append("Int16")
			case .UInt16: Append("UInt16")
			case .Int32: Append("Int32")
			case .UInt32: Append("UInt32")
			case .Int64: Append("Int64")
			case .UInt64: Append("UInt16")
			case .IntPtr: Append("Int")
			case .UIntPtr: Append("UInt")
			case .Single: Append("Float32")
			case .Double: Append("Float64")
			case .Boolean: Append("Bool")
			case .String: Append("String")
			case .AnsiChar: Append("AnsiChar")
			case .UTF16Char: Append("Char")
			case .UTF32Char: Append("Character")
			case .Dynamic: Append("AnyObject")
			case .InstanceType: Append("Self")
			case .Void: Append("()")
			case .Object: if Dialect == CGSwiftCodeGeneratorDialect.Silver { Append("Object") } else { Append("NSObject") }
			case .Class: Append("AnyClass")
		}		
		if !ignoreNullability {
			Append(swiftSuffixForNullability(type.Nullability, defaultNullability: type.DefaultNullability))
		}
	}

	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {
		swiftGenerateInlineBlockType(type.Block)
	}
	
	override func generatePointerTypeReference(type: CGPointerTypeReference) {
		Append("UnsafePointer<")
		generateTypeReference(type.`Type`)
		Append(">")
	}
	
	override func generateKindOfTypeReference(type: CGKindOfTypeReference) {
		if Dialect == CGSwiftCodeGeneratorDialect.Silver {
			Append("dynamic<")
			generateTypeReference(type.`Type`)
			Append(">")
		} else {
			assert(false, "generateKindOfTypeReference is not supported in Swift, except in Silver")
		}
	}
	
	override func generateTupleTypeReference(type: CGTupleTypeReference) {
		Append("(")
		for var m: Int32 = 0; m < type.Members.Count; m++ {
			if m > 0 {
				Append(", ")
			}
			generateTypeReference(type.Members[m])
		}
		Append(")")
	}
	
	override func generateSetTypeReference(setType: CGSetTypeReference) {
		assert(false, "generateSetTypeReference is not supported in Swift")
	}
	
	override func generateSequenceTypeReference(sequence: CGSequenceTypeReference) {
		if Dialect == CGSwiftCodeGeneratorDialect.Silver {
			Append("ISequence<")
			generateTypeReference(sequence.`Type`)
			Append(">")
		} else {
			assert(false, "generateSequenceTypeReference is not supported in Swift except in Silver")
		}
	}
	
	override func generateArrayTypeReference(array: CGArrayTypeReference) {
		
		var bounds = array.Bounds.Count
		if bounds == 0 {
			bounds = 1
		}
		switch (array.ArrayKind){
			case .Static:
				fallthrough
			case .Dynamic:
				generateTypeReference(array.`Type`)
				Append(swiftSuffixForNullabilityForCollectionType(array.`Type`))
				for var b: Int32 = 0; b < bounds; b++ {
					Append("[]")
				}
			case .HighLevel:
				for var b: Int32 = 0; b < bounds; b++ {
					Append("[")
				}
				generateTypeReference(array.`Type`)
				Append(swiftSuffixForNullabilityForCollectionType(array.`Type`))
				for var b: Int32 = 0; b < bounds; b++ {
					Append("]")
				}
		}
		Append(swiftSuffixForNullabilityForCollectionType(array))
		// bounds are not supported in Swift
	}
	
	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {
		Append("[")
		generateTypeReference(type.KeyType)
		Append(":")
		generateTypeReference(type.ValueType)
		Append("]")
		Append(swiftSuffixForNullabilityForCollectionType(type))
	}
	
	//
	// Helpers
	//

	private func removeWithPrefix(name: String) -> String {
		if name.ToLower().StartsWith("with") {
			name = name.Substring(4)
		}
		return lowercasecaseFirstletter(name)
	}
}

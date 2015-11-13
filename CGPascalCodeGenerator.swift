﻿import Sugar
import Sugar.Collections

//
// Abstract base implementation for all Pascal-style languages (Oxygene, Delphi)
//

public __abstract class CGPascalCodeGenerator : CGCodeGenerator {
	public var AlphaSortImplementationMembers: Boolean = false;

	override public init() {
		useTabs = false
		tabSize = 2
		keywordsAreCaseSensitive = false
	}

	public override var defaultFileExtension: String { return "pas" }

	override func doGenerateMemberImplementation(member: CGMemberDefinition, type: CGTypeDefinition) {
		pascalGenerateTypeMemberImplementation(member, type: type)
	}

	override func escapeIdentifier(name: String) -> String {
		if (!positionedAfterPeriod) {
			return "&\(name)"
		}
		return name
	}

	//
	// Pascal Special for interface/implementation separation
	//

	override func generateAll() {
		if !definitionOnly {
			generateHeader()
			generateDirectives()
			AppendLine("interface")
			AppendLine()
			pascalGenerateImports(currentUnit.Imports)
			generateGlobals()
		}
		if currentUnit.Types.Count > 0 {
			AppendLine("type")
			incIndent()
			generateTypeDefinitions()
			decIndent()
		}
		if !definitionOnly {
			AppendLine("implementation")
			AppendLine()
			pascalGenerateImports(currentUnit.ImplementationImports)
			pascalGenerateTypeImplementations()
			pascalGenerateGlobalImplementations()
			generateFooter()	
		}	
	}
	
	final func pascalGenerateTypeImplementations() {
		for t in currentUnit.Types {
			pascalGenerateTypeImplementation(t)
		}
	}
	
	final func pascalGenerateGlobalImplementations() {
		for g in currentUnit.Globals {
			pascalGenerateGlobalImplementation(g)
		}
	}

	//
	// Type Definitions
	//

	final func pascalGenerateTypeImplementation(type: CGTypeDefinition) {
		if let type = type as? CGClassTypeDefinition {
			pascalGenerateTypeMemberImplementations(type)
		} else if let type = type as? CGStructTypeDefinition {
			pascalGenerateTypeMemberImplementations(type)
		} else if let type = type as? CGExtensionTypeDefinition {
			pascalGenerateTypeMemberImplementations(type)
		}
	}

	final func pascalGenerateTypeMemberImplementations(type: CGTypeDefinition) {
		if AlphaSortImplementationMembers {
			var temp = List<CGMemberDefinition>()
			temp.AddRange(type.Members)
			temp.Sort({return $0.Name.CompareTo/*IgnoreCase*/($1.Name)})
			for m in temp {
				pascalGenerateTypeMemberImplementation(m, type: type)
			}
		} else {
			for m in type.Members {
				pascalGenerateTypeMemberImplementation(m, type: type)
			}
		}
	}
	
	final func pascalGenerateTypeMemberImplementation(member: CGMemberDefinition, type: CGTypeDefinition) {
		if let member = member as? CGConstructorDefinition {
			pascalGenerateConstructorImplementation(member, type:type)
		} else if let member = member as? CGDestructorDefinition {
			pascalGenerateDestructorImplementation(member, type:type)
		} else if let member = member as? CGFinalizerDefinition {
			pascalGenerateFinalizerImplementation(member, type:type)
		} else if let member = member as? CGMethodDefinition {
			pascalGenerateMethodImplementation(member, type:type)
		} else if let member = member as? CGPropertyDefinition {
			pascalGeneratePropertyImplementation(member, type:type)
		} else if let member = member as? CGEventDefinition {
			pascalGenerateEventImplementation(member, type:type)
		} else if let member = member as? CGCustomOperatorDefinition {
			pascalGenerateCustomOperatorImplementation(member, type:type)
		} else if let member = member as? CGNestedTypeDefinition {
			pascalGenerateNestedTypeImplementation(member, type:type)
		}
	}
	
	
	final func pascalGenerateGlobalImplementation(global: CGGlobalDefinition) {
		if let global = global as? CGGlobalFunctionDefinition {
			pascalGenerateMethodImplementation(global.Function, type: CGGlobalTypeDefinition.GlobalType)
		}
		else if let global = global as? CGGlobalVariableDefinition {
			// skip global variables
		}
		else {
			assert(false, "unsupported global found: \(typeOf(global).ToString())")
		}
	}

	//
	//
	//

	override func generateInlineComment(comment: String) {
		comment = comment.Replace("}", "*)")
		Append("{ \(comment) }")
	}
	
	internal func pascalGenerateImports(imports: List<CGImport>) {
		if imports.Count > 0 {
			AppendLine("uses")
			incIndent()
			for var i: Int32 = 0; i < imports.Count; i++ {
				generateIdentifier(imports[i].Name, alwaysEmitNamespace: true)
				if i < imports.Count-1 {
					AppendLine(",")
				} else {
					generateStatementTerminator()
				}
			}
			AppendLine()
			decIndent()
		}
	}
	
	override func generateFooter() {
		AppendLine("end.")
	}

	//
	// Statements
	//
	
	override func generateBeginEndStatement(statement: CGBeginEndBlockStatement) {
		AppendLine("begin")
		incIndent()
		generateStatementsSkippingOuterBeginEndBlock(statement.Statements)
		decIndent()
		Append("end")
		generateStatementTerminator()
	}

	override func generateIfElseStatement(statement: CGIfThenElseStatement) {
		Append("if ")
		generateExpression(statement.Condition)
		AppendLine(" then begin")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.IfStatement)
		decIndent()
		Append("end")
		if let elseStatement = statement.ElseStatement {
			AppendLine()
			AppendLine("else begin")
			incIndent()
			generateStatementSkippingOuterBeginEndBlock(elseStatement)
			decIndent()
			Append("end")
		}
		generateStatementTerminator()
	}

	override func generateForToLoopStatement(statement: CGForToLoopStatement) {
		Append("for ")
		generateIdentifier(statement.LoopVariableName)
		if let type = statement.LoopVariableType { //ToDo: classic Pascal cant do this?
			Append(": ")
			generateTypeReference(type)
		}
		Append(" := ")
		generateExpression(statement.StartValue)
		if statement.Direction == CGLoopDirectionKind.Forward {
			Append(" to ")
		} else {
			Append(" downto ")
		}
		generateExpression(statement.EndValue)
		Append(" do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateForEachLoopStatement(statement: CGForEachLoopStatement) {
		Append("for each ")
		generateIdentifier(statement.LoopVariableName)
		if let type = statement.LoopVariableType {
			Append(": ")
			generateTypeReference(type)
		}
		Append(" in ")
		generateExpression(statement.Collection)
		Append(" do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateWhileDoLoopStatement(statement: CGWhileDoLoopStatement) {
		Append("while ")
		generateExpression(statement.Condition)
		Append(" do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateDoWhileLoopStatement(statement: CGDoWhileLoopStatement) {
		Append("repeat")
		incIndent()
		generateStatementsSkippingOuterBeginEndBlock(statement.Statements)
		decIndent()
		Append("until ")
		if let notCondition = statement.Condition as? CGUnaryOperatorExpression where notCondition.Operator == CGUnaryOperatorKind.Not {
			generateExpression(notCondition.Value)
		} else {
			generateExpression(CGUnaryOperatorExpression.NotExpression(statement.Condition))
		}
	}

	/*
	override func generateInfiniteLoopStatement(statement: CGInfiniteLoopStatement) {
		// handled in base, Oxygene will override
	}
	*/

	override func generateSwitchStatement(statement: CGSwitchStatement) {
		Append("case ")
		generateExpression(statement.Expression)
		AppendLine(" of")
		incIndent()
		for c in statement.Cases {
			generateExpression(c.CaseExpression)
			AppendLine(": begin")
			incIndent()
			incIndent()
			generateStatementsSkippingOuterBeginEndBlock(c.Statements)
			decIndent()
			Append("end")
			generateStatementTerminator()
			decIndent()
		}
		if let defaultStatements = statement.DefaultCase where defaultStatements.Count > 0 {
			AppendLine("else begin")
			incIndent()
			generateStatementsSkippingOuterBeginEndBlock(defaultStatements)
			decIndent()
			Append("end")
			generateStatementTerminator()
		}
		decIndent()
		Append("end")
		generateStatementTerminator()
	}

	override func generateLockingStatement(statement: CGLockingStatement) {
		assert(false, "generateLockingStatement is not supported in base Pascal, only Oxygene")
	}

	override func generateUsingStatement(statement: CGUsingStatement) {
		assert(false, "generateUsingStatement is not supported in base Pascal, only Oxygene")
	}

	override func generateAutoReleasePoolStatement(statement: CGAutoReleasePoolStatement) {
		assert(false, "generateAutoReleasePoolStatement is not supported in base Pascal, only Oxygene")
	}

	override func generateTryFinallyCatchStatement(statement: CGTryFinallyCatchStatement) {
		//todo: override for Oxygene to get rid of the double try, once tested
		if let finallyStatements = statement.FinallyStatements where finallyStatements.Count > 0 {
			AppendLine("try")
			incIndent()
		}
		if let catchBlocks = statement.CatchBlocks where catchBlocks.Count > 0 {
			AppendLine("try")
			incIndent()
		}
		generateStatements(statement.Statements)
		if let finallyStatements = statement.FinallyStatements where finallyStatements.Count > 0 {
			decIndent()
			AppendLine("finally")
			incIndent()
			generateStatements(finallyStatements)
			decIndent()
			Append("end")
			generateStatementTerminator()
		}
		if let catchBlocks = statement.CatchBlocks where catchBlocks.Count > 0 {
			decIndent()
			AppendLine("except")
			incIndent()
			for b in catchBlocks {
				if let type = b.`Type` {
					Append("on ")
					generateIdentifier(b.Name)
					Append(": ")
					generateTypeReference(type)
					AppendLine(" do begin")
					incIndent()
					generateStatements(b.Statements)
					decIndent()
					Append("end")
					generateStatementTerminator()
				} else {
					assert(catchBlocks.Count == 1, "Can only have a single Catch block, if there is no type filter")
					generateStatements(b.Statements)
				}
			}
			decIndent()
			Append("end")
			generateStatementTerminator()
		}
	}

	override func generateReturnStatement(statement: CGReturnStatement) {
		if let value = statement.Value {
			Append("result := ")
			generateExpression(value)
			generateStatementTerminator()
		}
		Append("exit")
		generateStatementTerminator()
	}

	override func generateThrowStatement(statement: CGThrowStatement) {
		Append("raise")
		if let value = statement.Exception {
			Append(" ")
			generateExpression(value)
		}
		generateStatementTerminator()
	}

	override func generateBreakStatement(statement: CGBreakStatement) {
		AppendLine("break:")
	}

	override func generateContinueStatement(statement: CGContinueStatement) {
		Append("continue")
		generateStatementTerminator()
	}

	override func generateVariableDeclarationStatement(statement: CGVariableDeclarationStatement) {
		assert(false, "generateVariableDeclarationStatement is not supported in base Pascal, only Oxygene")
	}

	override func generateAssignmentStatement(statement: CGAssignmentStatement) {
		generateExpression(statement.Target)
		Append(" := ")
		generateExpression(statement.Value)
		generateStatementTerminator()
	}

	override func generateConstructorCallStatement(statement: CGConstructorCallStatement) {
		if let callSite = statement.CallSite {
			generateExpression(callSite)
			if callSite is CGInheritedExpression {
				Append(" ")
			} else {
				Append(".")
			}
		}
		if let name = statement.ConstructorName {
			Append(name)
		} else {
			Append("Create")
		}
		Append("(")
		pascalGenerateCallParameters(statement.Parameters)
		Append(")")
		generateStatementTerminator()
	}

	//
	// Expressions
	//

	/*
	override func generateNamedIdentifierExpression(expression: CGNamedIdentifierExpression) {
		// handled in base
	}
	*/

	override func generateAssignedExpression(expression: CGAssignedExpression) {
		if expression.Inverted {
			Append("not ")
		}
		Append("assigned(")
		generateExpression(expression.Value)
		Append(")")
	}

	override func generateSizeOfExpression(expression: CGSizeOfExpression) {
		Append("sizeOf(")
		generateExpression(expression.Expression)
		Append(")")
	}

	override func generateTypeOfExpression(expression: CGTypeOfExpression) {
		Append("typeOf(")
		generateExpression(expression.Expression)
		Append(")")
	}

	override func generateDefaultExpression(expression: CGDefaultExpression) {
		// todo: check if pase Pascal has thosw, or only Oxygene
		Append("default(")
		generateTypeReference(expression.`Type`)
		Append(")")
	}

	override func generateSelectorExpression(expression: CGSelectorExpression) {
		assert(false, "generateSelectorExpression is not supported in base Pascal, only Oxygene")
	}

	override func generateTypeCastExpression(cast: CGTypeCastExpression) {
		if cast.ThrowsException {
			Append("(")
			generateExpression(cast.Expression)
			Append(" as ")
			generateTypeReference(cast.TargetType)
			Append(")")
		} else {
			generateTypeReference(cast.TargetType)
			Append("(")
			generateExpression(cast.Expression)
			Append(")")
		}
	}

	override func generateInheritedExpression(expression: CGInheritedExpression) {
		Append("inherited")
	}

	override func generateSelfExpression(expression: CGSelfExpression) {
		Append("self")
	}

	override func generateNilExpression(expression: CGNilExpression) {
		Append("nil")
	}

	override func generatePropertyValueExpression(expression: CGPropertyValueExpression) {
		Append(CGPropertyDefinition.MAGIC_VALUE_PARAMETER_NAME)
	}

	override func generateAwaitExpression(expression: CGAwaitExpression) {
		assert(false, "generateAwaitExpression is not supported in base Pascal, only Oxygene")
	}

	override func generateAnonymousMethodExpression(method: CGAnonymousMethodExpression) {
		if method.Lambda {
			Append("(")
			helpGenerateCommaSeparatedList(method.Parameters) {param in
				self.generateIdentifier(param.Name)
			}
			Append(") -> ")
			if method.Statements.Count == 1, let expression = method.Statements[0] as? CGExpression {
				generateExpression(expression)
			} else {
				AppendLine("begin")
				incIndent()
				generateStatements(method.LocalVariables)
				generateStatementsSkippingOuterBeginEndBlock(method.Statements)
				decIndent()
				Append("end")
			}

		} else {
			Append("method")
			if method.Parameters.Count > 0 {
				Append("(")
				helpGenerateCommaSeparatedList(method.Parameters) { param in
					self.generateIdentifier(param.Name)
					if let type = param.`Type` {
						self.Append(": ")
						self.generateTypeReference(type)
					}
				}
				AppendLine(")")
			}
			if let returnType = method.ReturnType {
				Append(": ")
				generateTypeReference(returnType)
			}
			AppendLine(" begin")
			incIndent()
			generateStatements(method.LocalVariables)
			generateStatementsSkippingOuterBeginEndBlock(method.Statements)
			decIndent()
			Append("end")
		}
	}

	override func generateAnonymousTypeExpression(expression: CGAnonymousTypeExpression) {
		assert(false, "generateAnonymousTypeExpression is not supported in base Pascal, only Oxygene")
	}

	override func generatePointerDereferenceExpression(expression: CGPointerDereferenceExpression) {
		Append("(")
		generateExpression(expression.PointerExpression)
		Append(")^")
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

	override func generateUnaryOperator(`operator`: CGUnaryOperatorKind) {
		switch (`operator`) {
			case .Plus: Append("+")
			case .Minus: Append("-")
			case .Not: Append("not ")
			case .AddressOf: Append("@")
			case .ForceUnwrapNullable: Append("{ NOT SUPPORTED }")
		}
	}

	override func generateBinaryOperator(`operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .Concat: fallthrough
			case .Addition: Append("+")
			case .Subtraction: Append("-")
			case .Multiplication: Append("*")
			case .Division: Append("/")
			case .LegacyPascalDivision: Append("div")
			case .Modulus: Append("mod")
			case .Equals: Append("=")
			case .NotEquals: Append("<>")
			case .LessThan: Append("<")
			case .LessThanOrEquals: Append("<=")
			case .GreaterThan: Append(">")
			case .GreatThanOrEqual: Append(">=")
			case .LogicalAnd: Append("and")
			case .LogicalOr: Append("or")
			case .LogicalXor: Append("xor")
			case .Shl: Append("shl")
			case .Shr: Append("shr")
			case .BitwiseAnd: Append("and")
			case .BitwiseOr: Append("or")
			case .BitwiseXor: Append("xor")
			//case .Implies:
			case .Is: Append("is")
			//case .IsNot:
			case .In: Append("in")
			//case .NotIn:
			case .Assign: Append(":=")
			//case .AssignAddition: 
			//case .AssignSubtraction:
			//case .AssignMultiplication:
			//case .AssignDivision: 
			//case .AddEvent: 
			//case .RemoveEvent: 
			default: Append("{ NOT SUPPORTED }")
		}
	}

	override func generateIfThenElseExpression(expression: CGIfThenElseExpression) {
		assert(false, "generateIfThenElseExpression is not supported in base Pascal, only Oxygene")
	}

	internal func pascalGenerateStorageModifierPrefix(type: CGTypeReference) {
		switch type.StorageModifier {
			case .Strong: break
			case .Weak: Append("weak ")
			case .Unretained: Append("unretained ")
		}
	}

	internal func pascalGenerateCallSiteForExpression(expression: CGMemberAccessExpression) -> Boolean {
		if let callSite = expression.CallSite {
			generateExpression(callSite)
			if callSite is CGInheritedExpression {
				Append(" ")
			} else {
				Append(".")
				return false
			}
		}
		return true
	}

	func pascalGenerateCallParameters(parameters: List<CGCallParameter>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			generateExpression(param.Value)
		}
	}

	func pascalGenerateAttributeParameters(parameters: List<CGCallParameter>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			if let name = param.Name {
				generateIdentifier(name)
				Append(" := ")
			}
			generateExpression(param.Value)
		}
	}

	func pascalGenerateDefinitionParameters(parameters: List<CGParameterDefinition>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				Append("; ")
			}
			switch param.Modifier {
				case .Var: Append("var ")
				case .Const: Append("const ")
				case .Out: Append("out ")
				case .Params: Append("params ") //todo: Oxygene ony?
				default:
			}
			generateIdentifier(param.Name)
			Append(": ")
			generateTypeReference(param.`Type`)
			if let defaultValue = param.DefaultValue {
				Append(" = ")
				generateExpression(defaultValue)
			}
		}
	}

	func pascalGenerateGenericParameters(parameters: List<CGGenericParameterDefinition>) {
		if let parameters = parameters where parameters.Count > 0 {
			Append("<")
			helpGenerateCommaSeparatedList(parameters) { param in
				if let variance = param.Variance {
					switch variance {
						case .Covariant: self.Append("out ")
						case .Contravariant: self.Append("in ")
					}
				}
				self.generateIdentifier(param.Name)
			}
			Append(">")
		}
	}

	func pascalGenerateGenericConstraints(parameters: List<CGGenericParameterDefinition>?, needSemicolon: Boolean = false) {
		if let parameters = parameters where parameters.Count > 0 {
			var needsWhere = true
			helpGenerateCommaSeparatedList(parameters) { param in
				if let constraints = param.Constraints where constraints.Count > 0 {
					if needsWhere {
						self.Append(" where ")
						needsWhere = false
					} else {
						self.Append(", ")
					}
					self.helpGenerateCommaSeparatedList(constraints) { constraint in
						self.generateIdentifier(param.Name)
						if let constraint = constraint as? CGGenericHasConstructorConstraint {
							self.Append(" has constructor")
						//todo: 72051: Silver: after "if let x = x as? Foo", x still has the less concrete type. Sometimes.
						} else if let constraint2 = constraint as? CGGenericIsSpecificTypeConstraint {
							self.Append(" is ")
							self.generateTypeReference(constraint2.`Type`)
						} else if let constraint2 = constraint as? CGGenericIsSpecificTypeKindConstraint {
							switch constraint2.Kind {
								case .Class: self.Append(" is class")
								case .Struct: self.Append(" is record")
								case .Interface: self.Append(" is interface")
							}
						}
					}
				}
			}
			if needSemicolon {
				Append(";")
			}
		}
	}

	func pascalGenerateAncestorList(type: CGClassOrStructTypeDefinition) {
		if type.Ancestors.Count > 0 || type.ImplementedInterfaces.Count > 0 {
			Append("(")
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
			Append(")")
		}
	}

	override func generateFieldAccessExpression(expression: CGFieldAccessExpression) {
		let needsEscape = pascalGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name, escaped: needsEscape)
	}

	/*
	override func generateArrayElementAccessExpression(expression: CGArrayElementAccessExpression) {
		// handled in base
	}
	*/

	override func generateMethodCallExpression(expression: CGMethodCallExpression) {
		let needsEscape = pascalGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name, escaped: needsEscape)
		Append("(")
		pascalGenerateCallParameters(expression.Parameters)
		Append(")")
	}

	override func generateNewInstanceExpression(expression: CGNewInstanceExpression) {
		generateTypeReference(expression.`Type`)
		Append(".")
		if let name = expression.ConstructorName {
			generateIdentifier(name)
		} else {
			Append("Create")
		}
		Append("(")
		pascalGenerateCallParameters(expression.Parameters)
		Append(")")
	}

	override func generateDestroyInstanceExpression(expression: CGDestroyInstanceExpression) {
		generateExpression(expression.Instance);
		Append(".Free");
	}

	override func generatePropertyAccessExpression(expression: CGPropertyAccessExpression) {
		let needsEscape = pascalGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name, escaped: needsEscape)
		if let params = expression.Parameters where params.Count > 0 {
			Append("[")
			pascalGenerateCallParameters(expression.Parameters)
			Append("]")
		}
	}

	override func generateStringLiteralExpression(expression: CGStringLiteralExpression) {
		let escapedString = expression.Value.Replace("'", "''")
		//todo: this is incomplete, we need to escape any invalid chars
		Append("'\(escapedString)'")
	}

	override func generateCharacterLiteralExpression(expression: CGCharacterLiteralExpression) {
		Append("#\(expression.Value as! UInt32)")
	}

	override func generateArrayLiteralExpression(array: CGArrayLiteralExpression) {
		Append("[")
		helpGenerateCommaSeparatedList(array.Elements) { e in
			self.generateExpression(e)
		}
		Append("]")
	}

	override func generateDictionaryExpression(expression: CGDictionaryLiteralExpression) {
		assert(false, "generateDictionaryExpression is not supported in Pascal")
	}

	//
	// Type Definitions
	//

	override func generateAttribute(attribute: CGAttribute) {
		Append("[")
		generateTypeReference(attribute.`Type`)
		if let parameters = attribute.Parameters where parameters.Count > 0 {
			Append("(")
			pascalGenerateAttributeParameters(parameters)
			Append(")")
		}
		AppendLine("]")
	}

	func pascalGenerateTypeVisibilityPrefix(visibility: CGTypeVisibilityKind) {
		// not supported/needed in base Pascal
	}

	func pascalGenerateStaticPrefix(isStatic: Boolean) {
		if isStatic {
			Append("static ")
		}
	}

	func pascalGenerateAbstractPrefix(isAbstract: Boolean) {
		if isAbstract {
			Append("abstract ")
		}
	}

	func pascalGenerateSealedPrefix(isSealed: Boolean) {
		if isSealed {
			Append("sealed ")
		}
	}

	func pascalGeneratePartialPrefix(isPartial: Boolean) {
		if isPartial {
			Append("partial ")
		}
	}

	__abstract func pascalGenerateMemberVisibilityKeyword(visibility: CGMemberVisibilityKind)

	func swiftGenerateStaticPrefix(isStatic: Boolean) {
		if isStatic {
			Append("static ")
		}
	}

	override func generateAliasType(type: CGTypeAliasDefinition) {
		generateIdentifier(type.Name)
		Append(" = ")
		generateTypeReference(type.ActualType)
		generateStatementTerminator()
	}

	override func generateBlockType(type: CGBlockTypeDefinition) {
		assert(false, "generateIfThenElseExpression is not supported in base Pascal, only Oxygene")
	}

	override func generateEnumType(type: CGEnumTypeDefinition) {
		generateIdentifier(type.Name)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		Append("enum (")
		for var m: Int32 = 0; m < type.Members.Count; m++ {
			if let member = type.Members[m] as? CGEnumValueDefinition {
				if m > 0 {
					Append(", ")
				}
				generateIdentifier(member.Name)
				if let value = member.Value {
					Append(" = ")
					generateExpression(value)
				}
			}
		}
		Append(")")
		if let baseType = type.BaseType {
			Append(" of ")
			generateTypeReference(baseType)
		}
		generateStatementTerminator()
	}

	override func generateClassTypeStart(type: CGClassTypeDefinition) {
		generateIdentifier(type.Name)
		pascalGenerateGenericParameters(type.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		pascalGenerateStaticPrefix(type.Static)
		pascalGeneratePartialPrefix(type.Partial)
		pascalGenerateAbstractPrefix(type.Abstract)
		pascalGenerateSealedPrefix(type.Sealed)
		Append("class")
		pascalGenerateAncestorList(type)
		pascalGenerateGenericConstraints(type.GenericParameters)
		AppendLine()
		incIndent()
	}

	override func generateClassTypeEnd(type: CGClassTypeDefinition) {
		decIndent()
		Append("end")
		generateStatementTerminator()
		pascalGenerateNestedTypes(type)
	}

	override func generateStructTypeStart(type: CGStructTypeDefinition) {
		generateIdentifier(type.Name)
		pascalGenerateGenericParameters(type.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		pascalGenerateStaticPrefix(type.Static)
		pascalGeneratePartialPrefix(type.Partial)
		pascalGenerateAbstractPrefix(type.Abstract)
		pascalGenerateSealedPrefix(type.Sealed)
		Append("record")
		pascalGenerateAncestorList(type)
		pascalGenerateGenericConstraints(type.GenericParameters)
		AppendLine()
		incIndent()
	}

	override func generateStructTypeEnd(type: CGStructTypeDefinition) {
		decIndent()
		Append("end")
		generateStatementTerminator()
		pascalGenerateNestedTypes(type)
	}

	internal func pascalGenerateNestedTypes(type: CGTypeDefinition) {
		for m in type.Members {
			if let nestedType = m as? CGNestedTypeDefinition {
				AppendLine()
				nestedType.`Type`.Name = nestedType.Name+" nested in "+type.Name // Todo: nasty hack.
				generateTypeDefinition(nestedType.`Type`)
			}
		}
	}

	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {
		generateIdentifier(type.Name)
		pascalGenerateGenericParameters(type.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		pascalGenerateSealedPrefix(type.Sealed)
		Append("interface")
		pascalGenerateAncestorList(type)
		pascalGenerateGenericConstraints(type.GenericParameters)
		AppendLine()
		incIndent()
	}

	override func generateInterfaceTypeEnd(type: CGInterfaceTypeDefinition) {
		decIndent()
		Append("end")
		generateStatementTerminator()
	}

	override func generateExtensionTypeEnd(type: CGExtensionTypeDefinition) {
		decIndent()
		Append("end")
		generateStatementTerminator()
	}

	//
	// Type Members
	//

	final func generateTypeMembers(type: CGTypeDefinition, forVisibility visibility: CGMemberVisibilityKind?) {
		var first = true
		for m in type.Members {
			if visibility == CGMemberVisibilityKind.Private {
				if let m = m as? CGPropertyDefinition {
					pascalGeneratePropertyAccessorDefinition(m, type: type)
				} else if let m = m as? CGEventDefinition {
					pascalGenerateEventAccessorDefinition(m, type: type)
				}
			}
			if let visibility = visibility {
				if m.Visibility == visibility{
					if first {
						decIndent()
						if visibility != CGMemberVisibilityKind.Unspecified {
							pascalGenerateMemberVisibilityKeyword(visibility)
							AppendLine()
						}
						first = false
						incIndent()
					}
					generateTypeMember(m, type: type)
				}
			} else {
				generateTypeMember(m, type: type)
			}
		}
	}

	override func generateTypeMembers(type: CGTypeDefinition) {
		if type is CGInterfaceTypeDefinition {
			generateTypeMembers(type, forVisibility: nil)
		} else {
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Unspecified)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Private)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Unit)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.UnitOrProtected)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.UnitAndProtected)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Assembly)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.AssemblyOrProtected)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.AssemblyAndProtected)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Protected)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Public)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Published)
		}
	}

	internal func pascalKeywordForMethod(method: CGMethodDefinition) -> String {
		if let returnType = method.ReturnType where !returnType.IsVoid {
			return "function"
		}
		return "procedure"
	}

	func pascalGenerateVirtualityModifiders(member: CGMemberDefinition) {
		switch member.Virtuality {
			//case .None
			case .Virtual: Append(" virtual;")
			case .Abstract: Append(" virtual; abstract;")
			case .Override: Append(" override; ")
			//case .Final: /* Oxygene only*/
			case .Reintroduce: Append(" reintroduce;")
			default:
		}
	}

	internal func pascalGenerateSecondHalfOfMethodHeader(method: CGMethodLikeMemberDefinition, implementation: Boolean) {
		if let parameters = method.Parameters where parameters.Count > 0 {
			Append("(")
			pascalGenerateDefinitionParameters(parameters)
			Append(")")
		}
		if let returnType = method.ReturnType where !returnType.IsVoid {
			Append(": ")
			returnType.startLocation = currentLocation
			generateTypeReference(returnType)
			returnType.endLocation = currentLocation
		}
		Append(";")

		if !implementation {

			if let method = method as? CGMethodDefinition {
				pascalGenerateGenericConstraints(method.GenericParameters, needSemicolon: true)
			}

			pascalGenerateVirtualityModifiders(method)
			if method.External {
				Append(" external;")
			}
			if method.Async {
				Append(" async;")
			}
			if method.Partial {
				Append(" partial;")
			}
			if method.Empty {
				Append(" empty;")
			}
			if method.Locked {
				Append(" locked")
				if let lockedOn = method.LockedOn {
					Append(" on ")
					generateExpression(lockedOn)
				}
				Append(";")
			}
			if method.Overloaded {
				Append(" overload;")
			}
		}

		AppendLine()
	}

	internal func pascalGenerateMethodHeader(method: CGMethodLikeMemberDefinition, type: CGTypeDefinition, methodKeyword: String, implementation: Boolean) {
		if method.Static {
			Append("class ")
		}

		Append(methodKeyword)
		Append(" ")
		if implementation && !(type is CGGlobalTypeDefinition) {
			generateIdentifier(type.Name)
			Append(".")
		}
		generateIdentifier(method.Name)
		if let realMethod = method as? CGMethodDefinition, genericParameter = realMethod.GenericParameters {
			pascalGenerateGenericParameters(genericParameter)
		}
		pascalGenerateSecondHalfOfMethodHeader(method, implementation: implementation)
	}

	internal func pascalGenerateConstructorHeader(method: CGMethodLikeMemberDefinition, type: CGTypeDefinition, methodKeyword: String, implementation: Boolean) {
		if method.Static {
			Append("class ")
		}

		Append("constructor")
		Append(" ")
		if implementation {
			generateIdentifier(type.Name)
			Append(".")
		}
		if length(method.Name) > 0 {
			generateIdentifier(method.Name)
		} else {
			Append("Create")
		}
		pascalGenerateSecondHalfOfMethodHeader(method, implementation: implementation)
	}

	internal func pascalGenerateMethodBody(method: CGMethodLikeMemberDefinition, type: CGTypeDefinition) {
		if let localVariables = method.LocalVariables where localVariables.Count > 0 {
			AppendLine("var")
			incIndent()
			for v in localVariables {
				if let type = v.`Type` {
					generateIdentifier(v.Name)
					Append(": ")
					generateTypeReference(type)
					generateStatementTerminator()
				}
			}
			decIndent()
		}
		AppendLine("begin")
		incIndent()
		generateStatementsSkippingOuterBeginEndBlock(method.Statements)
		decIndent()
		Append("end")
		generateStatementTerminator()
		AppendLine()
	}

	override func generateMethodDefinition(method: CGMethodDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(method, type: type, methodKeyword:pascalKeywordForMethod(method), implementation: false)
	}

	func pascalGenerateMethodImplementation(method: CGMethodDefinition, type: CGTypeDefinition) {
		if (method.Virtuality != CGMemberVirtualityKind.Abstract) && !method.External && !method.Empty {
			pascalGenerateMethodHeader(method, type: type, methodKeyword: pascalKeywordForMethod(method), implementation: true)
			pascalGenerateMethodBody(method, type: type)
		}
	}

	override func generateConstructorDefinition(ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		pascalGenerateConstructorHeader(ctor, type: type, methodKeyword: "constructor", implementation: false)
	}

	func pascalGenerateConstructorImplementation(ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		if ctor.Virtuality != CGMemberVirtualityKind.Abstract && !ctor.External && !ctor.Empty {
			pascalGenerateConstructorHeader(ctor, type: type, methodKeyword: "constructor", implementation: true)
			pascalGenerateMethodBody(ctor, type: type)
		}
	}

	override func generateDestructorDefinition(dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(dtor, type: type, methodKeyword: "destructor", implementation: false)
	}

	func pascalGenerateDestructorImplementation(dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(dtor, type: type, methodKeyword: "destructor", implementation: true)
		pascalGenerateMethodBody(dtor, type: type)
	}

	override func generateFinalizerDefinition(finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		assert(false, "generateFinalizerDefinition is not supported in base Pascal, only Oxygene")
	}

	func pascalGenerateFinalizerImplementation(finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		assert(false, "generateFinalizerImplementation is not supported in base Pascal, only Oxygene")
	}

	override func generateCustomOperatorDefinition(customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(customOperator, type: type, methodKeyword: "operator", implementation: false)
	}

	func pascalGenerateCustomOperatorImplementation(customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(customOperator, type: type, methodKeyword: "operator", implementation: true)
		pascalGenerateMethodBody(customOperator, type: type)
	}

	func pascalGenerateNestedTypeImplementation(nestedType: CGNestedTypeDefinition, type: CGTypeDefinition) {
		nestedType.`Type`.Name = type.Name+"."+nestedType.Name // Todo: nasty hack.
		pascalGenerateTypeImplementation(nestedType.`Type`)
	}

	override func generateNestedTypeDefinition(member: CGNestedTypeDefinition, type: CGTypeDefinition) {
		// no-op
	}

	override func generateFieldDefinition(variable: CGFieldDefinition, type: CGTypeDefinition) {
		if variable.Static {
			Append("class ")
		}
		if variable.Constant, let initializer = variable.Initializer {
			Append("const ")
			generateIdentifier(variable.Name)
			if let type = variable.`Type` {
				Append(": ")
				generateTypeReference(type)
			}
			Append(" = ")
			generateExpression(initializer)
		} else {
			Append("var ")
			generateIdentifier(variable.Name)
			if let type = variable.`Type` {
				Append(": ")
				pascalGenerateStorageModifierPrefix(type)
				generateTypeReference(type)
			}
			if let initializer = variable.Initializer { // todo: Oxygene only?
				Append(" := ")
				generateExpression(initializer)
			}
		}
		generateStatementTerminator()
	}

	override func generatePropertyDefinition(property: CGPropertyDefinition, type: CGTypeDefinition) {
		if property.Static {
			Append("class ")
		}
		Append("property ")
		generateIdentifier(property.Name)
		if let parameters = property.Parameters where parameters.Count > 0 {
			Append("[")
			pascalGenerateDefinitionParameters(parameters)
			Append("]")
		}
		if let type = property.`Type` {
			Append(": ")
			pascalGenerateStorageModifierPrefix(type)
			generateTypeReference(type)
		}

		// todo: initializer for properties?
		
		if property.IsShortcutProperty {

			if type is CGInterfaceTypeDefinition || property.Virtuality == CGMemberVirtualityKind.Abstract {
			
				if !property.WriteOnly {
					Append(" read")
				}
				if !property.ReadOnly {
					Append(" write")
				}
			
			} else {
			
				if let value = property.Initializer {
					Append(" := ")
					generateExpression(value)
				}
				if property.ReadOnly {
					Append("; readonly")
				}
			}
			
		} else {
			
			if let getStatements = property.GetStatements, getterMethod = property.GetterMethodDefinition() {
				Append(" read")
				if !definitionOnly {
					Append(" ")
					generateIdentifier(getterMethod.Name)
				}
			} else if let getExpression = property.GetExpression {
				Append(" read")
				if !definitionOnly {
					Append(" ")
					generateExpression(getExpression)
				}
			}
	
			if let setStatements = property.SetStatements, setterMethod = property.SetterMethodDefinition() {
				Append(" write")
				if !definitionOnly {
					Append(" ")
					generateIdentifier(setterMethod.Name)
				}
			} else if let setExpression = property.SetExpression {
				Append(" write")
				if !definitionOnly {
					Append(" ")
					generateExpression(setExpression)
				}
			}
		}
		Append(";")

		if property.Default {
			Append(" default;")
		}
		pascalGenerateVirtualityModifiders(property)
		AppendLine()
	}

	func pascalGeneratePropertyAccessorDefinition(property: CGPropertyDefinition, type: CGTypeDefinition) {
		if !definitionOnly {
			if let getStatements = property.GetStatements, getterMethod = property.GetterMethodDefinition() {
				generateMethodDefinition(getterMethod, type: type)
			}
			if let setStatements = property.SetStatements, setterMethod = property.SetterMethodDefinition() {
				generateMethodDefinition(setterMethod!, type: type)
			}
		}
	}

	func pascalGeneratePropertyImplementation(property: CGPropertyDefinition, type: CGTypeDefinition) {
		if let getStatements = property.GetStatements {
			pascalGenerateMethodImplementation(property.GetterMethodDefinition()!, type: type)
		}
		if let setStatements = property.SetStatements {
			pascalGenerateMethodImplementation(property.GetterMethodDefinition()!, type: type)
		}
	}

	override func generateEventDefinition(event: CGEventDefinition, type: CGTypeDefinition) {
		assert(false, "generateEventDefinition is not supported in base Pascal, only Oxygene")
	}

	func pascalGenerateEventAccessorDefinition(property: CGEventDefinition, type: CGTypeDefinition) {
		assert(false, "pascalGenerateEventAccessorDefinition is not supported in base Pascal, only Oxygene")
	}

	func pascalGenerateEventImplementation(event: CGEventDefinition, type: CGTypeDefinition) {
		assert(false, "pascalGenerateEventImplementation is not supported in base Pascal, only Oxygene")
	}

	//
	// Type References
	//

	/*
	override func generateNamedTypeReference(type: CGNamedTypeReference) {
		// handled in base
	}
	*/

	override func generatePredefinedTypeReference(type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch (type.Kind) {
			case .Int: Append("Integer")
			case .UInt: Append("")
			case .Int8: Append("")
			case .UInt8: Append("Byte")
			case .Int16: Append("")
			case .UInt16: Append("Word")
			case .Int32: Append("Integer")
			case .UInt32: Append("")
			case .Int64: Append("")
			case .UInt64: Append("")
			case .IntPtr: Append("")
			case .UIntPtr: Append("")
			case .Single: Append("")
			case .Double: Append("")
			case .Boolean: Append("")
			case .String: Append("")
			case .AnsiChar: Append("")
			case .UTF16Char: Append("")
			case .UTF32Char: Append("")
			case .Dynamic: Append("{DYNAMIC}")
			case .InstanceType: Append("{INSTANCETYPE}")
			case .Void: Append("{VOID}")
			case .Object: Append("Object")
			case .Class: Append("")
		}		
	}

	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {
		assert(false, "generateInlineBlockTypeReference is not supported in base Pascal, only Oxygene")
	}

	override func generatePointerTypeReference(type: CGPointerTypeReference) {
		Append("^")
		generateTypeReference(type.`Type`)
	}

	override func generateKindOfTypeReference(type: CGKindOfTypeReference) {
		assert(false, "generateKindOfTypeReference is not supported in base Pascal, only Oxygene")
	}
	
	override func generateTupleTypeReference(type: CGTupleTypeReference) {
		assert(false, "generateTupleTypeReference is not supported in base Pascal, only Oxygene")
	}

	override func generateSetTypeReference(setType: CGSetTypeReference) {
		Append("set of ")
		generateTypeReference(setType.`Type`, ignoreNullability: true)
	}

	override func generateSequenceTypeReference(sequence: CGSequenceTypeReference) {
		assert(false, "generateSequenceTypeReference is not supported in base Pascal, only Oxygene")
	}

	override func generateArrayTypeReference(array: CGArrayTypeReference) {
		Append("array")
		if let bounds = array.Bounds where bounds.Count > 0 {
			Append("[")
			for var b: Int32 = 0; b < array.Bounds.Count; b++ {
				let bound = array.Bounds[b]
				if b > 0 {
					Append(", ")
				}
				Append(bound.Start.ToString())
				Append("..")
				if let end = bound.End {
					Append(end.ToString())
				}
			}
			Append("]")
		}
		Append(" of ")
		generateTypeReference(array.`Type`)
	}

	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {
		assert(false, "generateDictionaryTypeReference is not supported in Pascal")
	}
}

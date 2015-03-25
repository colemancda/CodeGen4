﻿import Sugar
import Sugar.Collections

//
// Abstract base implementation for Objective-C. Inherited by specific .m and .h Generators
//

public class CGObjectiveCCodeGenerator : CGCStyleCodeGenerator {

	//
	// Statements
	//
	
	// in C-styleCG Base class
	/*override func generateBeginEndStatement(statement: CGBeginEndBlockStatement) {
	}*/

	/*override func generateIfElseStatement(statement: CGIfElseStatement) {
	}*/

	/*override func generateForToLoopStatement(statement: CGForToLoopStatement) {
	}*/

	override func generateForEachLoopStatement(statement: CGForEachLoopStatement) {
		Append("for (")
		generateIdentifier(statement.LoopVariableName)
		Append(" in ")
		generateExpression(statement.Collection)
		AppendLine(")")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	/*override func generateWhileDoLoopStatement(statement: CGWhileDoLoopStatement) {
	}*/

	/*override func generateDoWhileLoopStatement(statement: CGDoWhileLoopStatement) {
	}*/

	/*override func generateInfiniteLoopStatement(statement: CGInfiniteLoopStatement) {
	}*/

	override func generateSwitchStatement(statement: CGSwitchStatement) {
		//todo
	}

	override func generateLockingStatement(statement: CGLockingStatement) {
		AppendLine("@synchnonized")
		AppendLine("{")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("}")
	}

	override func generateUsingStatement(statement: CGUsingStatement) {
		assert(false, "generateUsingStatement is not supported in Objective-C")
	}

	override func generateAutoReleasePoolStatement(statement: CGAutoReleasePoolStatement) {
		AppendLine("@autoreleasepool")
		AppendLine("{")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("}")
	}

	override func generateTryFinallyCatchStatement(statement: CGTryFinallyCatchStatement) {
		AppendLine("@try")
		AppendLine("{")
		incIndent()
		generateStatements(statement.Statements)
		decIndent()
		AppendLine("}")
		if let finallyStatements = statement.FinallyStatements where finallyStatements.Count > 0 {
			AppendLine("finally")
			AppendLine("{")
			incIndent()
			generateStatements(finallyStatements)
			decIndent()
			AppendLine("}")
		}
		if let catchBlocks = statement.CatchBlocks where catchBlocks.Count > 0 {
			for b in catchBlocks {
				if let type = b.`Type` {
					Append("catch (")
					generateTypeReference(type)
					Append(" ")
					generateIdentifier(b.Name)
					AppendLine(")")
				} else {
					AppendLine("catch")
				}
				AppendLine("{")
				incIndent()
				generateStatements(b.Statements)
				decIndent()
				AppendLine("}")
			}
		}
	}

	/*override func generateReturnStatement(statement: CGReturnStatement) {
	}*/

	override func generateThrowStatement(statement: CGThrowStatement) {
		if let value = statement.Exception {
			Append("throw ")
			generateExpression(value)
			AppendLine()
		} else {
			AppendLine("throw")
		}
		cStyleGenerateStatementTerminator()
	}

	/*override func generateBreakStatement(statement: CGBreakStatement) {
	}*/

	/*override func generateContinueStatement(statement: CGContinueStatement) {
	}*/

	override func generateVariableDeclarationStatement(statement: CGVariableDeclarationStatement) {
		if let type = statement.`Type` {
			generateTypeReference(type)
			Append(" ")
		} else {
			Append("id ")
		}		
		generateIdentifier(statement.Name)
		if let value = statement.Value {
			Append(" = ")
			generateExpression(value)
		}
		cStyleGenerateStatementTerminator()
	}

	/*override func generateAssignmentStatement(statement: CGAssignmentStatement) {
	}*/	
	
	//
	// Type Definitions
	//
	
	override func generateAliasType(type: CGTypeAliasDefinition) {

	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		
	}
	
	override func generateEnumType(type: CGEnumTypeDefinition) {
		
	}
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {
		
	}
	
	override func generateClassTypeEnd(type: CGClassTypeDefinition) {
		decIndent()
		AppendLine("@end")
	}
	
	override func generateStructTypeStart(type: CGStructTypeDefinition) {

	}
	
	override func generateStructTypeEnd(type: CGStructTypeDefinition) {

	}	
	
	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {

	}
	
	override func generateInterfaceTypeEnd(type: CGInterfaceTypeDefinition) {
		decIndent()
		AppendLine("@end")
	}	
	
	//
	// Type Members
	//
	
	override func generateMethodDefinition(member: CGMethodDefinition, type: CGTypeDefinition) {

	}
	
	//
	// Type References
	//

	override func generateNamedTypeReference(type: CGNamedTypeReference) {

	}
	
	override func generatePredefinedTypeReference(type: CGPredfinedTypeReference) {
		switch (type.Kind) {
			case .Int8: Append("");
			case .UInt8: Append("");
			case .Int16: Append("");
			case .UInt16: Append("");
			case .Int32: Append("");
			case .UInt32: Append("");
			case .Int64: Append("");
			case .UInt64: Append("");
			case .IntPtr: Append("");
			case .UIntPtr: Append("");
			case .Single: Append("");
			case .Double: Append("")
			case .Boolean: Append("")
			case .String: Append("")
			case .AnsiChar: Append("")
			case .UTF16Char: Append("")
			case .UTF32Char: Append("")
			case .Dynamic: Append("")
			case .InstanceType: Append("")
			case .Void: Append("")
			case .Object: Append("")
		}		
	}

	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {

	}
	
	override func generateArrayTypeReference(type: CGArrayTypeReference) {

	}
	
	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {

	}
}
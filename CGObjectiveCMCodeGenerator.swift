﻿import Sugar
import Sugar.Collections
import Sugar.IO

public class CGObjectiveCMCodeGenerator : CGObjectiveCCodeGenerator {

	override func generateHeader() {
		
		if let fileName = currentUnit.FileName {
			Append("#import \"\(Path.ChangeExtension(fileName, ".h"))\"")
		}
	}
	
	override func generateImport(imp: CGImport) {
		// ignore imports,they are in the .h
	}

	//
	// Types
	//
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {
		Append("@implementation ")
		generateIdentifier(type.Name)
		AppendLine()
		
		var hasFields = false
		for m in type.Members {
			if let field = m as? CGFieldDefinition {
				if !hasFields {
					hasFields = true
					AppendLine("{")
					incIndent();
				}
				if let type = field.`Type` {
					generateTypeReference(type)
					Append(" ")
				} else {
					Append("id ")
				}
				generateIdentifier(field.Name)
				AppendLine(";")
			}
		}
		if hasFields {
			decIndent()
			AppendLine("}")
		}
		
		AppendLine()
	}
	
	//
	// Type Members
	//
	
	override func generateMethodDefinition(method: CGMethodDefinition, type: CGTypeDefinition) {
		generateMethodDefinitionHeader(method, type: type)
		AppendLine()
		AppendLine("{")
		incIndent()
		generateStatements(method.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateConstructorDefinition(ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		generateMethodDefinitionHeader(ctor, type: type)
		AppendLine()
		AppendLine("{")
		incIndent()
		generateStatements(ctor.Statements)
		decIndent()
		AppendLine("}")
	}
	
	override func generateFieldDefinition(field: CGFieldDefinition, type: CGTypeDefinition) {
		if field.Static {
			Append("static ")
			if let type = field.`Type` {
				generateTypeReference(type)
				Append(" ")
			} else {
				Append("id ")
			}
			generateIdentifier(field.Name)
			AppendLine(";")
		}
		// instance fields are generated in TypeStart
	}
	
}
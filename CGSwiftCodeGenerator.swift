﻿import Sugar
import Sugar.Collections

public enum CGSwiftCodeGeneratorDialect {
	case Standard
	case Silver
}

public class CGSwiftCodeGenerator : CGCStyleCodeGenerator {

	public var Dialect: CGSwiftCodeGeneratorDialect = .Standard

	override func escapeIdentifier(name: String) -> String {
		return "`\(name)`"
	}

	override func generateImport(imp: CGImport) {
		Append("import \(imp.Name)")
	}

	/* Types */
	
	override func generateAliasType(type: CGTypeAliasDefinition) {
		Append("typealias ")
		generateIdentifier(type.Name)
		Append(" = ")
		generateTypeReference(type.ActualType)
		AppendLine()
	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
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
			generateTypeReference(block.Parameters[p].`Type`)
		}
		Append(") -> ")
		if let returnType = block.ReturnType {
			generateTypeReference(returnType)
		} else {
			Append("()")
		}
	}
	
	override func generateEnumType(type: CGEnumTypeDefinition) {
		
	}
	
	override func generateClassType(type: CGClassTypeDefinition) {
		generateClassOrStructType(type)
	}
	
	override func generateStructType(type: CGStructTypeDefinition) {
		generateClassOrStructType(type)
	}
	
	func generateClassOrStructType(type: CGClassOrStructTypeDefinition) {
	}
	
	/* Type References */
	
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
	
	override func generateNamedTypeReference(type: CGNamedTypeReference) {
		generateIdentifier(type.Name)
		Append(swiftSuffixForNullability(type.Nullability, defaultNullability: type.DefaultNullability))
	}
	
	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {
		swiftGenerateInlineBlockType(type.Block)
	}
	
	override func generateArrayTypeReference(type: CGArrayTypeReference) {
		
		switch (type.ArrayKind){
			case .Static:
				fallthrough
			case .Dynamic:
				generateTypeReference(type.`Type`)
				Append("[]")
			case .HighLevel:
				Append("[")
				generateTypeReference(type.`Type`)
				Append("]")
		}
		//ToDo: bounds & dimensions
	}
	
	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {
			Append("[")
			generateTypeReference(type.KeyType)
			Append(":")
			generateTypeReference(type.ValueType)
			Append("]")
	}
	
}
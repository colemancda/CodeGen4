﻿import Sugar
import Sugar.Collections

public class CGObjectiveCHCodeGenerator : CGObjectiveCCodeGenerator {

	public override var defaultFileExtension: String { return "h" }

	override func generateForwards() {
		for t in currentUnit.Types {
			if let type = t as? CGClassTypeDefinition {
				Append("@class ")
				generateIdentifier(type.Name)
				AppendLine(";")
			} else if let type = t as? CGInterfaceTypeDefinition {
				Append("@protocol ")
				generateIdentifier(type.Name)
				AppendLine(";")
			}
		}
	}
	
	override func generateImport(imp: CGImport) {
		AppendLine("#import <\(imp.Name)/\(imp.Name).h>")
	}

	//
	// Types
	//
	
	override func generateAliasType(type: CGTypeAliasDefinition) {

	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		
	}
	
	override func generateEnumType(type: CGEnumTypeDefinition) {
		Append("typedef NS_ENUM(")
		if let baseType = type.BaseType {
			generateTypeReference(baseType, ignoreNullability: true)
		} else {
			Append("NSUInteger")
		}
		Append(", ")
		generateIdentifier(type.Name)
		AppendLine(")")
		AppendLine("{")
		incIndent()
		for var m = 0; m < type.Members.Count; m++ {
			if let member = type.Members[m] as? CGEnumValueDefinition {
				if m > 0 {
					AppendLine(",")
				}
				generateIdentifier(member.Name)
				if let value = member.Value {
					Append(" = ")
					generateExpression(value)
				}
			}
		}
		AppendLine()
		decIndent()
		AppendLine("};")
	}
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {
		Append("@interface ")
		generateIdentifier(type.Name)
		objcGenerateAncestorList(type)
		AppendLine()
		AppendLine()
	}
	
	/*override func generateClassTypeEnd(type: CGClassTypeDefinition) {
		decIndent()
		AppendLine(@"end")
	}*/
	
	override func generateStructTypeStart(type: CGStructTypeDefinition) {

	}
	
	override func generateStructTypeEnd(type: CGStructTypeDefinition) {

	}	
	
	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {
		Append("@protocol ")
		generateIdentifier(type.Name)
		objcGenerateAncestorList(type)
		AppendLine()
		AppendLine()
	}
	
	override func generateInterfaceTypeEnd(type: CGInterfaceTypeDefinition) {
		AppendLine()
		AppendLine("@end")
	}	

	//
	// Type Members
	//
	
	override func generateMethodDefinition(method: CGMethodDefinition, type: CGTypeDefinition) {
		generateMethodDefinitionHeader(method, type: type)
		AppendLine(";")
	}
	
	override func generateConstructorDefinition(ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		generateMethodDefinitionHeader(ctor, type: type)
		AppendLine(";")
	}
	
	override func generatePropertyDefinition(property: CGPropertyDefinition, type: CGTypeDefinition) {
		
		if property.Virtuality == CGMemberVirtualityKind.Override || property.Virtuality == CGMemberVirtualityKind.Final {
			Append("// overriden ") // we don't need to re-emit overriden properties in header?
		}
		
		Append("@property ")
		
		Append("(")
		if property.Atomic {
			Append("atomic")
		} else {
			Append("nonatomic")
		}
		if let type = property.`Type` {
			if type.IsClassType {
				switch type.StorageModifier {
					case .Strong: Append(", strong")
					case .Weak: Append(", weak")
					case .Unretained: Append(", unsafe_unretained")
				}
			} else {
				//todo?
			}
		}
		if property.ReadOnly {
			Append(", readonly")
		}
		Append(") ")
		
		if let type = property.`Type` {
			generateTypeReference(type)
			if !objcTypeRefereneIsPointer(type) {
				Append(" ")
			}
		} else {
			Append("id ")
		}
		generateIdentifier(property.Name)
		AppendLine(";")
	}
}
﻿import Sugar
import Sugar.Collections

public __abstract class CGEntity {
}

public class CGCodeUnit {
	
	public var FileName: String?
	public var Namespace: CGNamespaceReference?
	public var HeaderComment = CGCommentStatement()
	public var Directives = List<String>() /* will not be language agnostic */
	public var Imports = List<CGImport>()
	public var Types = List<CGTypeDefinition>()
	public var Globals = List<CGGlobalDefinition>()
	
	public var ImplementationImports = List<CGImport>() /* Delphi only */
	public var Initialization: List<CGStatement>? /* Delphi only */
	public var Finalization: List<CGStatement>? /* Delphi only */

	public init() {
	}
	public init(_ namespace: String) {
		Namespace = CGNamespaceReference(namespace)
	}
	public init(_ namespace: CGNamespaceReference) {
		Namespace = namespace
	}
}

public class CGImport {
	public var Namespace: CGNamespaceReference?
	public var StaticClass: CGNamedTypeReference?
	
	public var Name: String? {
		if let ns = Namespace {
			return ns.Name
		} else if let sc = StaticClass {
			return sc.Name
		}
		return nil
	}

	public init(_ namespace: String) {
		Namespace = CGNamespaceReference(namespace)
	}
	public init(_ namespace: CGNamespaceReference) {
		Namespace = namespace
	}
	public init(_ staticClass: CGNamedTypeReference) {
		StaticClass = staticClass
	}
}

public class CGNamespaceReference {
	public var Name: String
	public var IsStaticClass = false /* C# only */

	public init(_ name: String) {
		Name = name
	}
}

public __abstract class CGGlobalDefinition {
}

public class CGGlobalFunctionDefinition : CGGlobalDefinition {
	public var Function: CGMethodDefinition

	public init(_ function: CGMethodDefinition) {
		Function = function
	}
}

public class CGGlobalVariableDefinition : CGGlobalDefinition {
	public var Variable: CGFieldDefinition
	
	public init(_ variable: CGFieldDefinition) {
		Variable = variable
	}
}

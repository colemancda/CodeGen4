﻿public extension String {
	
	public func AsTypeReference() -> CGTypeReference {
		return CGNamedTypeReference(self)
	}

	public func AsTypeReferenceExpression() -> CGTypeReferenceExpression {
		return CGTypeReferenceExpression(CGNamedTypeReference(self))
	}
	
	public func AsLiteralExpression() -> CGStringLiteralExpression {
		return CGStringLiteralExpression(self)
	}
}

public extension Char {
	public func AsLiteralExpression() -> CGCharacterLiteralExpression {
		return CGCharacterLiteralExpression(self)
	}
}

public extension Integer {
	public func AsLiteralExpression() -> CGIntegerLiteralExpression {
		return CGIntegerLiteralExpression(self)
	}
}

public extension Single {
	public func AsLiteralExpression() -> CGFloatLiteralExpression {
		return CGFloatLiteralExpression(self)
	}
}

public extension Double {
	public func AsLiteralExpression() -> CGFloatLiteralExpression {
		return CGFloatLiteralExpression(self)
	}
}

public extension Boolean {
	public func AsLiteralExpression() -> CGBooleanLiteralExpression {
		return CGBooleanLiteralExpression(self)
	}
}

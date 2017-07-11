module theories::AST

import IO;

data Problem = problem(Universe uni, list[RelationalBound] bounds, list[AlleFormula] constraints);

data Universe = universe(list[AtomDecl] atoms);

data AtomDecl 
  = atomOnly(Atom atom)
  | atomWithAttributes(Atom atom, list[Attribute] attributes)
  ;

data Attribute
  = attribute(str name, Theory theory)
  | attributeAndValue(str name, Theory theory, Value val)
  ;

data Value = none();

data RelationalBound = relationalBound(str relName, int arity, list[Tuple] lowerBounds, list[Tuple] upperBounds);

data Tuple = \tuple(list[Atom] atoms);  

data AlleFormula
  = empty(Expr expr)
  | atMostOne(Expr expr)
  | exactlyOne(Expr expr)
  | nonEmpty(Expr expr)
  | subset(Expr lhsExpr, Expr rhsExpr)
  | equal(Expr lhsExpr, Expr rhsExpr)
  | inequal(Expr lhsExpr, Expr rhsExpr)
  | negation(AlleFormula form)
  | conjunction(AlleFormula lhsForm, AlleFormula rhsForm)
  | disjunction(AlleFormula lhsForm, AlleFormula rhsForm)
  | implication(AlleFormula lhsForm, AlleFormula rhsForm)
  | equality(AlleFormula lhsForm, AlleFormula rhsForm)
  | universal(list[VarDeclaration] decls, AlleFormula form)
  | existential(list[VarDeclaration] decls, AlleFormula form) 
  ; 
 
data Expr
  = variable(str name)
  | attributeLookup(Expr expr, str name)
  | transpose(Expr expr)
  | closure(Expr expr)
  | reflexClosure(Expr expr)
  | union(Expr lhs, Expr rhs) 
  | intersection(Expr lhs, Expr rhs)
  | difference(Expr lhs, Expr rhs)
  | \join(Expr lhs, Expr rhs)
  | accessorJoin(Expr col, Expr select)
  | product(Expr lhs, Expr rhs)
  | ifThenElse(AlleFormula caseForm, Expr thenExpr, Expr elseExpr)
  | comprehension(list[VarDeclaration] decls, AlleFormula form)
  ;

data VarDeclaration = varDecl(str name, Expr binding);

alias Atom = str;

data Theory = relTheory();

default Expr rewrite(Expr e) = e;
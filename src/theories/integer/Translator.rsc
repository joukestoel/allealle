module theories::integer::Translator

extend theories::Translator;

import logic::Integer;
import logic::Boolean;

import theories::integer::AST;

import theories::AST; 
import theories::Binder;
import theories::Translator;
 
import List;  
import Map;
 
import IO;
 
AttributeFormula constructAttribute(Atom a, Formula relForm, attribute(str name, intTheory())) = <relForm, equal(intVar("<a>!<name>"),intVar("<a>!<name>"))>;
AttributeFormula constructAttribute(Atom a, Formula relForm, attributeAndValue(str name, intTheory(), intExpr(Expr expr))) = <relForm, equal(intVar("<a>!<name>"), exprToForm(expr))>;

Formula exprToForm(intLit(int i))                              = \int(i);
Formula exprToForm(neg(Expr e))                                = neg(exprToForm(e));
Formula exprToForm(attributeLookup(variable(str v), str name)) = var("<v>!<name>"); 
Formula exprToForm(multiplication(list[Expr] terms))           = multiplication([exprToForm(t) | Expr t <- terms]);
Formula exprToForm(division(Expr lhs, Expr rhs))               = division(exprToForm(lhs), exprToForm(rhs));
Formula exprToForm(modulo(Expr lhs, Expr rhs))                 = modulo(exprToForm(lhs), exprToForm(rhs));
Formula exprToForm(addition(list[Expr] terms))                 = addition([exprToForm(t) | Expr t <- terms]);
Formula exprToForm(subtraction(Expr lhs, Expr rhs))            = substraction(exprToForm(lhs), exprToForm(rhs));

Formula translateFormula(gt(Expr lhsExpr, Expr rhsExpr), Environment env, Universe uni, AdditionalConstraintFunctions acf) = translateFormula(lhs, rhs, Formula (Formula l, Formula r) { return gt(l, r);}, acf)
  when RelationAndAttributes lhs := translateExpression(lhsExpr, env, uni, acf),
       RelationAndAttributes rhs := translateExpression(rhsExpr, env, uni, acf);

Formula translateFormula(gte(Expr lhsExpr, Expr rhsExpr), Environment env, Universe uni, AdditionalConstraintFunctions acf) = translateFormula(lhs, rhs, Formula (Formula l, Formula r) { return gte(l, r);}, acf)
  when RelationAndAttributes lhs := translateExpression(lhsExpr, env, uni, acf),
       RelationAndAttributes rhs := translateExpression(rhsExpr, env, uni, acf);

Formula translateFormula(lt(Expr lhsExpr, Expr rhsExpr), Environment env, Universe uni, AdditionalConstraintFunctions acf) = translateFormula(lhs, rhs, Formula (Formula l, Formula r) { return lt(l, r);}, acf)
  when RelationAndAttributes lhs := translateExpression(lhsExpr, env, uni, acf),
       RelationAndAttributes rhs := translateExpression(rhsExpr, env, uni, acf);

Formula translateFormula(lte(Expr lhsExpr, Expr rhsExpr), Environment env, Universe uni, AdditionalConstraintFunctions acf) = translateFormula(lhs, rhs, Formula (Formula l, Formula r) { return lte(l, r);}, acf)
  when RelationAndAttributes lhs := translateExpression(lhsExpr, env, uni, acf),
       RelationAndAttributes rhs := translateExpression(rhsExpr, env, uni, acf);

Formula translateFormula(intEqual(Expr lhsExpr, Expr rhsExpr), Environment env, Universe uni, AdditionalConstraintFunctions acf) = translateFormula(lhs, rhs, Formula (Formula l, Formula r) { return equal(l, r);}, acf) 
  when RelationAndAttributes lhs := translateExpression(lhsExpr, env, uni, acf),
       RelationAndAttributes rhs := translateExpression(rhsExpr, env, uni, acf);

Formula translateFormula(intInequal(Expr lhsExpr, Expr rhsExpr), Environment env, Universe uni, AdditionalConstraintFunctions acf) = translateFormula(lhs, rhs, Formula (Formula l, Formula r) { return inequal(l, r);}, acf) 
  when RelationAndAttributes lhs := translateExpression(lhsExpr, env, uni, acf),
       RelationAndAttributes rhs := translateExpression(rhsExpr, env, uni, acf);

Formula translateFormula(RelationAndAttributes lhs, RelationAndAttributes rhs, Formula (Formula lhsElement, Formula rhsElement) operation, AdditionalConstraintFunctions acf) {
  if (arity(lhs) == 0 || arity(rhs) == 0) { return \true(); }
  
  if (arity(lhs) != 1 || arity(rhs) != 1) {
    println(lhs); println(rhs);
    throw "Unable to perform an integer equation on non-unary relations";
  }
  
  Formula result = \true();
  
  for(Index lhsIdx <- lhs.relation) {
    set[Formula] ors = {};
 
    for (Index rhsIdx <- rhs.relation) {
      if (0 notin lhs.att[lhsIdx] || 0 notin rhs.att[rhsIdx]) {
        throw "Can not perform an integer equation on relations that do not capture integer constraints";
      }
      if (size(lhs.att[lhsIdx][0]) != 1 || size(rhs.att[rhsIdx][0]) != 1) {
        throw "Can only perform an integer equation on selected integer attributes";      
      }
      
      Formula tmpResult = \true(); 
         
      for ({set[AttributeFormula] lhsAttribute} := lhs.att[lhsIdx][0]<1>, {set[AttributeFormula] rhsAttribute} := rhs.att[rhsIdx][0]<1>,
           l:<Formula lhsRelForm, equal(lhsIntVar:intVar(str _), Formula _)> <- lhsAttribute, 
           r:<Formula rhsRelForm, equal(rhsIntVar:intVar(str _), Formula _)> <- rhsAttribute) {
        
        tmpResult = \and(tmpResult, operation(lhsIntVar, rhsIntVar));
        
        acf.addAttributeConstraint(l);
        acf.addAttributeConstraint(r); 
      }
      
      ors += \or(\not(rhs.relation[rhsIdx]), tmpResult); 
    }

    result = \and(result, \or(\not(lhs.relation[lhsIdx]), \and(ors)));
  }    
  
  return result; 
}       

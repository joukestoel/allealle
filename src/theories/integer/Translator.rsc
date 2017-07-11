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
 
TheoryFormula constructTheoryFormula(str relName, Formula relForm, atomAndTheory(Atom a, intTheory())) = form(relForm, equal(intVar("<relName>_<a>_int"), intVar("<a>")));
TheoryFormula constructTheoryFormula(str relName, Formula relForm, atomTheoryAndValue(Atom a, intTheory(), intExpr(Expr expr))) {
  if (f:\int(int i) := exprToForm(expr)) {
    return form(relForm, equal(intVar("<relName>_<a>_int"), f));
  } else {
    return form(relForm, equal(intVar("<relName>_<a>_int"), intVar("<a>")));
  }
}

Formula exprToForm(intLit(int i))                       = \int(i);
Formula exprToForm(neg(Expr e))                         = neg(exprToForm(e));
Formula exprToForm(variable(str v))                     = var(v);
//Formula exprToForm(multiplication(Expr lhs, Expr rhs))  = multiplication(exprToForm(lhs), exprToForm(rhs));
Formula exprToForm(multiplication(list[Expr] terms))    = multiplication([exprToForm(t) | Expr t <- terms]);
Formula exprToForm(division(Expr lhs, Expr rhs))        = division(exprToForm(lhs), exprToForm(rhs));
Formula exprToForm(modulo(Expr lhs, Expr rhs))          = modulo(exprToForm(lhs), exprToForm(rhs));
//Formula exprToForm(addition(Expr lhs, Expr rhs))        = addition(exprToForm(lhs), exprToForm(rhs));
Formula exprToForm(addition(list[Expr] terms))          = addition([exprToForm(t) | Expr t <- terms]);
Formula exprToForm(subtraction(Expr lhs, Expr rhs))     = substraction(exprToForm(lhs), exprToForm(rhs));

//@memo
Formula translateFormula(gt(Expr lhsExpr, Expr rhsExpr), Environment env, Universe uni, void (set[TheoryFormula]) addTheoryConstraint, void (Formula) addAdditionalConstraint) = translateFormula(lhs, rhs, Formula (Formula l, Formula r) { return gt(l, r);}, addTheoryConstraint, addAdditionalConstraint)
  when RelationMatrix lhs := translateExpression(lhsExpr, env, uni, addTheoryConstraint, addAdditionalConstraint),
       RelationMatrix rhs := translateExpression(rhsExpr, env, uni, addTheoryConstraint, addAdditionalConstraint);

//@memo
Formula translateFormula(gte(Expr lhsExpr, Expr rhsExpr), Environment env, Universe uni, void (set[TheoryFormula]) addTheoryConstraint, void (Formula) addAdditionalConstraint) = translateFormula(lhs, rhs, Formula (Formula l, Formula r) { return gte(l, r);}, addTheoryConstraint, addAdditionalConstraint)
  when RelationMatrix lhs := translateExpression(lhsExpr, env, uni, addTheoryConstraint, addAdditionalConstraint),
       RelationMatrix rhs := translateExpression(rhsExpr, env, uni, addTheoryConstraint, addAdditionalConstraint);

//@memo
Formula translateFormula(lt(Expr lhsExpr, Expr rhsExpr), Environment env, Universe uni, void (set[TheoryFormula]) addTheoryConstraint, void (Formula) addAdditionalConstraint) = translateFormula(lhs, rhs, Formula (Formula l, Formula r) { return lt(l, r);}, addTheoryConstraint, addAdditionalConstraint)
  when RelationMatrix lhs := translateExpression(lhsExpr, env, uni, addTheoryConstraint, addAdditionalConstraint),
       RelationMatrix rhs := translateExpression(rhsExpr, env, uni, addTheoryConstraint, addAdditionalConstraint);

//@memo       
Formula translateFormula(lte(Expr lhsExpr, Expr rhsExpr), Environment env, Universe uni, void (set[TheoryFormula]) addTheoryConstraint, void (Formula) addAdditionalConstraint) = translateFormula(lhs, rhs, Formula (Formula l, Formula r) { return lte(l, r);}, addTheoryConstraint, addAdditionalConstraint)
  when RelationMatrix lhs := translateExpression(lhsExpr, env, uni, addTheoryConstraint, addAdditionalConstraint),
       RelationMatrix rhs := translateExpression(rhsExpr, env, uni, addTheoryConstraint, addAdditionalConstraint);

//@memo       
Formula translateFormula(intEqual(Expr lhsExpr, Expr rhsExpr), Environment env, Universe uni, void (set[TheoryFormula]) addTheoryConstraint, void (Formula) addAdditionalConstraint) = translateFormula(lhs, rhs, Formula (Formula l, Formula r) { return equal(l, r);}, addTheoryConstraint, addAdditionalConstraint) 
  when RelationMatrix lhs := translateExpression(lhsExpr, env, uni, addTheoryConstraint, addAdditionalConstraint),
       RelationMatrix rhs := translateExpression(rhsExpr, env, uni, addTheoryConstraint, addAdditionalConstraint);

//@memo
Formula translateFormula(intInequal(Expr lhsExpr, Expr rhsExpr), Environment env, Universe uni, void (set[TheoryFormula]) addTheoryConstraint, void (Formula) addAdditionalConstraint) = translateFormula(lhs, rhs, Formula (Formula l, Formula r) { return inequal(l, r);}, addTheoryConstraint, addAdditionalConstraint) 
  when RelationMatrix lhs := translateExpression(lhsExpr, env, uni, addTheoryConstraint, addAdditionalConstraint),
       RelationMatrix rhs := translateExpression(rhsExpr, env, uni, addTheoryConstraint, addAdditionalConstraint);

Formula translateFormula(RelationMatrix lhs, RelationMatrix rhs, Formula (Formula lhsElement, Formula rhsElement) operation, void (set[TheoryFormula]) addTheoryConstraint, void (Formula) addAdditionalConstraint) {
  if (arity(lhs) == 0 || arity(rhs) == 0) { return \true(); }
  
  if (arity(lhs) != 1 || arity(rhs) != 1) {
    println(lhs); println(rhs);
    throw "Unable to perform an integer equation on non-unary relations";
  }
  
  Formula result = \true();
  
  for(Index lhsIdx <- lhs) {
    set[Formula] ors = {};

    for (Index rhsIdx <- rhs) {
      if (0 notin lhs[lhsIdx].ext || 0 notin rhs[rhsIdx].ext) {
        throw "Can not perform an integer equation on relations that do not capture integer constraints";
      }
      
      Formula tmpResult = \true();   
         
      for (l:form(Formula lhsRelForm, equal(lhsIntVar:intVar(str _), Formula _)) <- lhs[lhsIdx].ext[0], r:form(Formula rhsRelForm, equal(rhsIntVar:intVar(str _), Formula _)) <- rhs[rhsIdx].ext[0]) {
        tmpResult = \and(tmpResult, operation(lhsIntVar, rhsIntVar));
        
        addTheoryConstraint({l});
        addTheoryConstraint({r}); 
      }
      
      ors += \or(\not(rhs[rhsIdx].relForm), tmpResult); 
    }

    result = \and(result, \or(\not(lhs[lhsIdx].relForm), \and(ors)));
  }    
  
  return result; 
}       

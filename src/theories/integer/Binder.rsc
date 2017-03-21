module theories::integer::Binder

extend theories::Binder;

import logic::Integer;
import theories::integer::AST;

RelationMatrix multiply(RelationMatrix lhs, RelationMatrix rhs) = translate(lhs, rhs, Formula (Formula l, Formula r) { return multiplication(l,r); });
RelationMatrix divide(RelationMatrix lhs, RelationMatrix rhs) = translate(lhs, rhs, Formula (Formula l, Formula r) { return division(l,r); }); 
RelationMatrix add(RelationMatrix lhs, RelationMatrix rhs) = translate(lhs, rhs, Formula (Formula l, Formula r) { return addition(l,r); });
RelationMatrix substract(RelationMatrix lhs, RelationMatrix rhs) = translate(lhs, rhs, Formula (Formula l, Formula r) { return substraction(l,r); }); 

RelationMatrix gt(RelationMatrix lhs, RelationMatrix rhs) = translate(lhs, rhs, Formula (Formula l, Formula r) { return gt(l,r); });
RelationMatrix gte(RelationMatrix lhs, RelationMatrix rhs) = translate(lhs, rhs, Formula (Formula l, Formula r) { return gte(l,r); });
RelationMatrix lt(RelationMatrix lhs, RelationMatrix rhs) = translate(lhs, rhs, Formula (Formula l, Formula r) { return lt(l,r); });
RelationMatrix lte(RelationMatrix lhs, RelationMatrix rhs) = translate(lhs, rhs, Formula (Formula l, Formula r) { return lte(l,r); });
RelationMatrix lte(RelationMatrix lhs, RelationMatrix rhs) = translate(lhs, rhs, Formula (Formula l, Formula r) { return lte(l,r); });
RelationMatrix equal(RelationMatrix lhs, RelationMatrix rhs) = translate(lhs, rhs, Formula (Formula l, Formula r) { return equal(l,r); });

private RelationMatrix translate(RelationMatrix lhs, RelationMatrix rhs, Formula (Formula, Formula) operation) 
  = (currentLhs + currentRhs : <val, (intTheory(): {operation(lhsIntVal, rhsIntVal) | Formula lhsIntVal <- lhs[currentLhs].ext[intTheory()], Formula rhsIntVal <- rhs[currentRhs].ext[intTheory()]})> | 
      Index currentLhs <- lhs, 
      lhs[currentLhs].relForm != \false(),
      intTheory() in lhs[currentLhs].ext,
      Index currentRhs <- rhs, 
      rhs[currentRhs].relForm != \false(),
      intTheory() in rhs[currentRhs].ext,
      Formula val := and(lhs[currentLhs].relForm, rhs[currentRhs].relForm), 
      val !:= \false()); 
   
  //= (<a + b:operation(lhs[a], rhs[b]) | Index a <- lhs, a.theory == intTheory(), Index b <- rhs, b.theory == intTheory()) + product(lhs, rhs);

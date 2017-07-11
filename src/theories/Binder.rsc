module theories::Binder

import logic::Propositional;
import theories::AST;

import List;
import Map;
import Set;
import IO;

data TheoryFormula = form(Formula relForm, Formula theoryForm); 

alias ExtensionEncoding = map[int, set[TheoryFormula]];
alias Content = tuple[Formula relForm,  ExtensionEncoding ext];
alias Index = list[Atom]; 
alias RelationMatrix = map[Index, Content];

alias Environment = map[str, RelationMatrix]; 

@memo
int sizeOfUniverse(Universe u) = size(u.atoms);

@memo int arity(RelationMatrix rm) = 0 when rm == ();
@memo int arity(RelationMatrix rm) = size(getOneFrom(rm)) when rm != ();

@memo
private bool sameArity(RelationMatrix lhs, RelationMatrix rhs) = arity(lhs) == arity(rhs); 

private RelationMatrix square(RelationMatrix m, int i, int sizeOfUniverse, void (set[TheoryFormula]) addTheoryConstraint) = m when i >= sizeOfUniverse;
private RelationMatrix square(RelationMatrix m, int i, int sizeOfUniverse, void (set[TheoryFormula]) addTheoryConstraint) = or(n, \join(n, n, addTheoryConstraint)) when RelationMatrix n := square(m, i * 2, sizeOfUniverse, addTheoryConstraint); 

private list[Index] constructIdentityIndex(int arity, Universe uni) = [vector | AtomDecl ad <- uni.atoms, list[Atom] vector := [ad.atom | int _ <- [0..arity]]];

@memo
RelationMatrix identity(RelationMatrix orig, Universe uni) = identity(arity(orig), uni);
RelationMatrix identity(int arity, Universe uni) = (idx:<\true(),()> | Index idx <- constructIdentityIndex(arity, uni));

ExtensionEncoding merge(ExtensionEncoding lhs, ExtensionEncoding rhs) = (idx : lhs[idx] | int idx <- lhs, idx notin rhs) +
                                                                        (idx : lhs[idx] + rhs[idx] | int idx <- lhs, idx in rhs) +
                                                                        (idx : rhs[idx] | int idx <- rhs, idx notin lhs);

RelationMatrix or(RelationMatrix lhs, RelationMatrix rhs) 
  = (x:<\or(lhsVal,rhsVal), merge(lhsExt, rhsExt)> | Index x <- (lhs + rhs), Formula lhsVal := ((x in lhs) ? lhs[x].relForm : \false()), Formula rhsVal := ((x in rhs) ? rhs[x].relForm : \false()), ExtensionEncoding lhsExt := ((x in lhs) ? lhs[x].ext : ()), ExtensionEncoding rhsExt := ((x in rhs) ? rhs[x].ext : ())) 
  when sameArity(lhs, rhs);
default RelationMatrix or(RelationMatrix _, RelationMatrix _) { throw "Unable to perform disjunction of bindings with different arity"; }

RelationMatrix and(RelationMatrix lhs, RelationMatrix rhs) = (x:<\and(lhs[x].relForm, rhs[x].relForm), merge(lhs[x].ext, rhs[x].ext)> | Index x <- lhs, x in rhs) when sameArity(lhs, rhs);
default RelationMatrix and(RelationMatrix _, RelationMatrix _) { throw "Unable to perform conjunction of bindings with different arity"; }
 

private ExtensionEncoding transpose(ExtensionEncoding ext, 1) = ext;
private ExtensionEncoding transpose(ExtensionEncoding ext, int arity) = ((arity - 1) - idx : ext[idx] | int idx <- ext);
  
RelationMatrix transpose(RelationMatrix m) = (() | it + (reversedIndex : <m[key].relForm, transpose(m[key].ext, arity(m))>) | Index key <- m, Index reversedIndex := reverse(key));

RelationMatrix transitiveClosure(RelationMatrix m, Universe uni, void (set[TheoryFormula]) addTheoryConstraint, void (Formula) addAdditionalConstraint) = square(m, 1, sizeOfUniverse(uni), addTheoryConstraint) when arity(m) == 2;
default RelationMatrix transitiveClosure(RelationMatrix m, Universe uni, void (set[TheoryFormula]) addTheoryConstraint, void (Formula) addAdditionalConstraint) { throw "Can not perform a transitive closure on a non-binary relation"; }

RelationMatrix reflexiveTransitiveClosure(RelationMatrix m, Universe uni, void (set[TheoryFormula]) addTheoryConstraint, void (Formula) addAdditionalConstraint) = or(transitiveClosure(m, uni, addTheoryConstraint, addAdditionalConstraint), identity(m, uni)) when arity(m) == 2; 
default RelationMatrix reflexiveTransitiveClosure(RelationMatrix m, Universe uni, void (set[TheoryFormula]) addTheoryConstraint, void (Formula) addAdditionalConstraint) { throw "Can not perform a reflexive transitive closure on a non-binary relation"; }

RelationMatrix disjunction(RelationMatrix lhs, RelationMatrix rhs) = or(lhs, rhs) when sameArity(lhs, rhs);
default RelationMatrix disjunction(RelationMatrix lhs, RelationMatrix rhs) { throw "Relations to disjunct must be of same arity"; }
RelationMatrix conjunction(RelationMatrix lhs, RelationMatrix rhs) = and(lhs, rhs) when sameArity(lhs, rhs);
default RelationMatrix conjunction(RelationMatrix lhs, RelationMatrix rhs) { throw "Relations to conjunct must be of same arity"; }

RelationMatrix difference(RelationMatrix lhs, RelationMatrix rhs) = 
  (idx:<and(lhs[idx].relForm, rhsVal), lhs[idx].ext> | Index idx <- lhs, Formula rhsVal := ((idx in rhs) ? not(rhs[idx].relForm) : \true())) 
  when sameArity(lhs, rhs);
default RelationMatrix difference(RelationMatrix lhs, RelationMatrix rhs) { throw "Can not perform a difference on two relations with different arities"; }  

private Formula toRelForm(set[TheoryFormula] forms) = (\true() | \and(it, \if(f.relForm,f.theoryForm)) | TheoryFormula f <- forms);

@memo
RelationMatrix \join(RelationMatrix lhs, RelationMatrix rhs, void (set[TheoryFormula]) addTheoryConstraint) {
  int arityLhs = arity(lhs);
  int arityRhs = arity(rhs);
    
  if (arityLhs == 1 && arityRhs == 1) { throw "Unable to join two unary relations"; }
      
  set[Index] indicesEndingWith(Atom a, RelationMatrix b) = {idx | Index idx <- b, idx[-1] == a};
  set[Index] indicesStartingWith(Atom a, RelationMatrix b) = {idx | Index idx <- b, idx[0] == a};

  // join by joining the right-most atom from the index of the lhs with the left-most atom from the index of the rhs. It is much like a database join
  set[Atom] mostRightAtomInLhs = {idx[-1] | Index idx <- lhs};
    
  ExtensionEncoding joinExt(ExtensionEncoding lhsExt, ExtensionEncoding rhsExt) {
    ExtensionEncoding resultExt = (idx : lhsExt[idx]     | int idx <- lhsExt, idx < (arityLhs - 1)) +
                                  (idx - 1 : rhsExt[idx] | int idx <- rhsExt, idx > 0);
                               
    if (arityLhs - 1 in lhsExt) { addTheoryConstraint(lhsExt[arityLhs-1]); }
    if (0 in rhsExt) { addTheoryConstraint(rhsExt[0]); }
    
    return resultExt;
  }  
    
  RelationMatrix joinResult = ();
  for (Atom current <- mostRightAtomInLhs) {
    set[Index] lhsIndices = indicesEndingWith(current, lhs);
    set[Index] rhsIndices = indicesStartingWith(current, rhs);
    
    if (lhsIndices != {} && rhsIndices != {}) {  

      for (Index currentLhs <- lhsIndices, Formula lhsVal := lhs[currentLhs].relForm, lhsVal != \false(), Index currentRhs <- rhsIndices, Formula rhsVal := rhs[currentRhs].relForm, rhsVal != \false()) {
        Formula val = and(lhsVal, rhsVal);
        
        if (val != \false()) {
          Index jointIndex = (currentLhs - currentLhs[-1]) + (currentRhs - currentRhs[0]);
          ExtensionEncoding joinExtResult = joinExt(lhs[currentLhs].ext, rhs[currentRhs].ext); 

          if (jointIndex notin joinResult) {
            joinResult[jointIndex] = <val, joinExtResult>;
          }else {
            joinResult[jointIndex] = <or(joinResult[jointIndex].relForm, val), merge(joinResult[jointIndex].ext, joinExtResult)>;
          }
        }
      }
    }
  }
  
  return joinResult;
}

ExtensionEncoding productExt(int arityLhs, ExtensionEncoding lhs, ExtensionEncoding rhs) =
  lhs + (i + arityLhs : rhs[i] | int i <- rhs);

RelationMatrix product(RelationMatrix lhs, RelationMatrix rhs) 
  = (currentLhs + currentRhs : <val, productExt(arityLhs, lhs[currentLhs].ext, rhs[currentRhs].ext)> | 
      Index currentLhs <- lhs, 
      lhs[currentLhs].relForm != \false(),
      int arityLhs := arity(lhs),
      Index currentRhs <- rhs, 
      rhs[currentRhs].relForm != \false(),
      Formula val := and(lhs[currentLhs].relForm, rhs[currentRhs].relForm), 
      val !:= \false()); 


 


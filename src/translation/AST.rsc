module translation::AST

import util::Maybe;

extend translation::theories::integer::AST;
extend translation::theories::string::AST;

data Problem 
  = problem(list[RelationDef] relations, list[AlleFormula] constraints, map[str,AllePredicate] predicates, Maybe[ObjectiveSection] objectiveSec, Maybe[Expect] expect)
  ;

data RelationDef
  = relation(str name, list[HeaderAttribute] heading, RelationalBound bounds)
  ;

data HeaderAttribute
  = header(str name, Domain dom)
  ;

data RelationalBound
  = exact(list[AlleTuple] tuples)
  | atMost(list[AlleTuple] upper)
  | atLeastAtMost(list[AlleTuple] lower, list[AlleTuple] upper)
  ;

data AlleTuple 
  = tup(list[AlleValue] values)
  | range(list[RangedValue] from, list[RangedValue] to)
  ;  

data AlleValue
  = idd(Id id)
  | alleLit(AlleLiteral lit)
  | hole()
  ;

data RangedValue
  = id(str prefix, int numm)
  | idOnly(Id id)
  | templateLit(AlleLiteral lit)
  | templateHole()
  ;

alias Id = str;

data Domain 
  = id()
  ;
    
data AlleLiteral
  = idLit(Id id)
  ; 

data AllePredicate = pred(str name, list[PredParam] params, AlleFormula form);

data PredParam = predParam(str name, list[HeaderAttribute] heading);

data AlleFormula(loc origLoc = |unknown://|)
  = \filter(AlleExpr expr, Criteria criteria)
  | predCall(str pred, list[AlleExpr] args) 
  | empty(AlleExpr expr)
  | atMostOne(AlleExpr expr)
  | exactlyOne(AlleExpr expr)
  | nonEmpty(AlleExpr expr)
  | subset(AlleExpr lhsExpr, AlleExpr rhsExpr)
  | equal(AlleExpr lhsExpr, AlleExpr rhsExpr)
  | inequal(AlleExpr lhsExpr, AlleExpr rhsExpr)
  | negation(AlleFormula form)
  | conjunction(AlleFormula lhsForm, AlleFormula rhsForm)
  | disjunction(AlleFormula lhsForm, AlleFormula rhsForm)
  | implication(AlleFormula lhsForm, AlleFormula rhsForm)
  | equality(AlleFormula lhsForm, AlleFormula rhsForm)
  | let(list[VarBinding] bindings, AlleFormula form)
  | universal(list[VarDeclaration] decls, AlleFormula form)
  | existential(list[VarDeclaration] decls, AlleFormula form) 
  ; 
 
data AlleExpr
  = relvar(str name)
  | rename(AlleExpr expr, list[Rename] renames)
  | project(AlleExpr expr, list[str] attributes)
  | select(AlleExpr expr, Criteria criteria)
  | aggregate(AlleExpr expr, list[AggregateFunctionDef] functionDefs)
  | groupedAggregate(AlleExpr expr, list[str] groupBy, list[AggregateFunctionDef] functionDefs)
  | union(AlleExpr lhs, AlleExpr rhs)
  | intersection(AlleExpr lhs, AlleExpr rhs)
  | difference(AlleExpr lhs, AlleExpr rhs)
  | product(AlleExpr lhs, AlleExpr rhs)
  | naturalJoin(AlleExpr lhs, AlleExpr rhs)
  | transpose(AlleExpr expr)
  | closure(AlleExpr r)
  | reflexClosure(AlleExpr r)
  | comprehension(list[VarDeclaration] decls, AlleFormula form)
  ;

data VarDeclaration = varDecl(str name, AlleExpr binding);

data VarBinding = varBinding(str name, AlleExpr binding);

data TupleAttributeSelection 
  = order(str first, str second)
  ;

data Rename 
  = rename(str new, str orig)
  ;

data AggregateFunctionDef
  = aggFuncDef(AggregateFunction func, str bindTo)
  ;

data AggregateFunction;

data AggregateFunctionAttribute
  = aggAtt(str name)
  | func(AggregateFunction f)
  ;

data Criteria
  = equal(CriteriaExpr lhsExpr, CriteriaExpr rhsExpr)
  | inequal(CriteriaExpr lhsExpr, CriteriaExpr rhsExpr)
  | and(Criteria lhs, Criteria rhs)
  | or(Criteria lhs, Criteria rhs)
  | not(Criteria crit)
  ;


data CriteriaExpr
  = att(str name) 
  | litt(AlleLiteral l)
  | ite(Criteria condition, CriteriaExpr thn, CriteriaExpr els)
  ;

data ObjectiveSection
  = objectives(ObjectivePriority prio, list[Objective] objs)
  ;
  
data ObjectivePriority
  = lex()
  | pareto()
  | independent()
  ;  

data Objective
  = maximize(AlleExpr expr)
  | minimize(AlleExpr expr)  
  ; 
  
data Expect
  = expect(ResultType result)
  | expect(ResultType result, ModelRestriction restrict)
  ;
  
data ResultType
  = sat()
  | trivSat()
  | unsat()
  | trivUnsat()
  ;
  
data ModelRestriction
  = restrict(ModelRestrExpr expr, Domain d)
  ;
  
data ModelRestrExpr
  = eqMod(int nr)
  | ltMod(int nr)
  | gtMod(int nr)
  ;
module translation::Syntax

extend translation::Layout;

extend translation::theories::integer::Syntax;
extend translation::theories::string::Syntax;

start syntax Problem = problem: Relation* relations AlleConstraint* constraints ObjectiveSection? objSection Expect? expect;

syntax Relation 
  = RelVar v "(" {HeaderAttribute ","}+ header ")" RelationalBound bounds
  ;

syntax HeaderAttribute
  = AttributeName name ":" Domain dom
  ;

syntax AttributeHeader
  = header: AttributeName name ":" Domain dom
  ;

syntax RelationalBound
  = exact: "=" "{" {Tuple ","}*tuples "}"
  | atMost: "\<=" "{" {Tuple ","}* upper "}"
  | atLeastAtMost: "\>=" "{" {Tuple ","}+ lower "}" "\<=" "{" {Tuple ","}+ upper "}"
  ;

syntax Tuple 
  = tup: "\<" {Value ","}+ values "\>"
  | range: "\<" {RangedValue ","}+ from "\>" ".." "\<" {RangedValue ","}+ to "\>"
  ;  

syntax Value
  = Idd id
  | lit: Literal lit
  | "?"
  ;

syntax RangedValue
  = id: RangedId prefix RangedNr numm
  | idOnly: RangedId id
  | templateLit: Literal lit
  | "?"
  ;

syntax Domain 
  = "id"
  ;  
  
syntax Literal 
  = idLit: "\'" Idd id "\'" 
  ; 
 
syntax AlleConstraint
  = AlleFormula form
  | AllePredicate predDef
  ; 
 
syntax AllePredicate = "pred" Idd name "[" {PredParam ","}* params "]" "=" AlleFormula form; 

syntax PredParam = RelVar name ":" "(" {HeaderAttribute ","}+ header ")"; 
  
syntax AlleFormula
  = bracket "(" AlleFormula form ")"
  > predCall:           Idd predName "[" {AlleExpr ","}* args "]"
  > negation:           ("not"|"¬") AlleFormula form
  > empty:              "no" AlleExpr expr
  | atMostOne:          "lone" AlleExpr expr
  | exactlyOne:         "one" AlleExpr expr
  | nonEmpty:           "some" AlleExpr expr
  | subset:             AlleExpr lhsExpr ("in" | "⊆") AlleExpr rhsExpr
  | left equal:         AlleExpr lhsExpr "=" AlleExpr rhsExpr
  | left inequal:       AlleExpr lhsExpr ("!=" | "≠") AlleExpr rhsExpr
  > left conjunction:   AlleFormula lhsForm ("&&" | "∧") AlleFormula rhsForm
  | left disjunction:   AlleFormula lhsForm ("||" | "∨") AlleFormula rhsForm  
  > implication:        AlleFormula lhsForm ("=\>" | "⇒") AlleFormula rhsForm
  | equality:           AlleFormula lhsForm ("\<=\>" | "⇔") AlleFormula rhsForm
  > let:                "let" {VarBinding ","}+ bindings "|" AlleFormula form
  > universal:          ("forall" | "∀") {VarDeclaration ","}+ decls "|" AlleFormula form
  | existential:        ("exists" | "∃") {VarDeclaration ","}+ decls "|" AlleFormula form 
  ; 

syntax VarDeclaration = varDecl: RelVar var (":" | "∈") AlleExpr expr;

syntax VarBinding = varBinding: RelVar var "=" AlleExpr expr;

syntax AlleExpr
  = bracket "(" AlleExpr expr ")"
  > variable:           RelVar v
  | lit:                Literal l
  > rename:             AlleExpr r "[" {Rename ","}+ "]"
  | project:            AlleExpr r "[" {AttributeName ","}+ "]"
  | renameAndProject:   AlleExpr r "[" {ProjectAndRename ","}+ "]"
  | select:             AlleExpr r "where" Criteria criteria
  | aggregate:          AlleExpr r "[" {AggregateFunctionDef ","}+ "]"
  | groupedAggregate:   AlleExpr r "[" {AttributeName ","}+ groupBy "," {AggregateFunctionDef ","}+ aggregateFunctions "]"
  > transpose:          "~" AlleExpr r
  | closure:            "^" AlleExpr r
  | reflexClosure:      "*" AlleExpr r
  > left naturalJoin:   AlleExpr lhs ("|x|" | "⨝") AlleExpr rhs
  > left (union:        AlleExpr lhs ("+" | "∪")   AlleExpr rhs
         |intersection: AlleExpr lhs ("&" | "∩")  AlleExpr rhs
         |difference:   AlleExpr lhs ("-" | "∖")   AlleExpr rhs
         |product:      AlleExpr lhs ("x" | "⨯")   AlleExpr rhs
         )
  | comprehension:     "{" {VarDeclaration ","}+ decls "|" AlleFormula form "}"
  //| ifThenElse:         AlleFormula form "?" AlleExpr then ":" AlleExpr else
  ;

syntax TupleAttributeSelection 
  = "\<" AttributeName first "," AttributeName second "\>"
  ;

syntax Rename = AttributeName orig "as" AttributeName new;

syntax ProjectAndRename = AttributeName orig "-\>" AttributeName new;

syntax AggregateFunctionDef 
  = AggregateFunction func
  | AggregateFunction func "as" AttributeName bindTo
  ;

syntax AggregateFunction
  = dummy: " " !>> " "
  ;
  
syntax Criteria
  = bracket "(" Criteria ")"
  > "not" Criteria
  > non-assoc 
    ( CriteriaExpr lhsExpr "=" CriteriaExpr rhsExpr
    | CriteriaExpr lhsExpr "!=" CriteriaExpr rhsExpr
    )
  > left ( Criteria lhs "&&" Criteria rhs
         | Criteria lhs "||" Criteria rhs
         )
  ;

syntax CriteriaExpr
  = bracket "(" CriteriaExpr ")"
  | AttributeName att
  | Literal l
  > left Criteria condition "?" CriteriaExpr thn ":" CriteriaExpr els
  ;
  
syntax ObjectiveSection
  = "objectives" ":" {Objective ","}+ objectives
  | "objectives" "(" ObjectivePriority prio ")" ":" {Objective ","}+ objectives 
  ;
    
  
syntax ObjectivePriority
  = "lex"
  | "pareto"
  | "independent"
  ;  
  
syntax Objective  
 = maximize: "maximize" AlleExpr expr
 | minimize: "minimize" AlleExpr expr
 ;
 
syntax Expect
  = "expect" ":" ResultType result ("," ModelRestriction models)?
  ;

syntax ResultType
  = "sat"
  | "trivial-sat"
  | "unsat"
  | "trivial-unsat"
  ;
  
syntax ModelRestriction
 = "#" "models" ("(" Domain dom ")")? ModelRestrExpr expr
 ;

syntax ModelRestrExpr
 = "=" Arity
 | "\>" Arity
 | "\<" Arity
 ;   
 
lexical RangedId = ([a-zA-Z_] !<< [a-zA-Z_][a-zA-Z_\-.]* !>> [a-zA-Z_\-.]) \ Keywords; //([a-z_] !<< [a-z_][a-zA-Z_]* !>> [a-zA-Z_]) \ Keywords;
lexical RangedNr = [0-9]+;

lexical Idd = ([a-zA-Z_] !<< [a-zA-Z_][a-zA-Z_\-0-9.]* !>> [a-zA-Z_\-0-9.]) \ Keywords;

//lexical Id = ([a-z_] !<< [a-z][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Keywords;
lexical AttributeName = ([a-zA-Z] !<< [a-zA-Z][a-zA-Z0-9_\']* !>> [a-zA-Z0-9_]) \ Keywords;
lexical Arity = [0-9]+;

lexical RelVar = ([a-zA-Z_] !<< [a-zA-Z_][a-zA-Z0-9_\']* !>> [a-zA-Z0-9_]) \ Keywords;

keyword Keywords = "none" | "|x|" | "where" | "objectives" | "as";
keyword Keywords = "no" | "lone" | "one" | "some" | "not" | "forall" | "exists" | "let";
keyword Keywords = "expect" | "sat" | "unsat" | "t-sat" | "t-unsat";

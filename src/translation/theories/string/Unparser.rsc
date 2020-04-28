module translation::theories::string::Unparser

import translation::theories::string::AST; 

str unparse(strDom())       = "str";
str unparse(strLit(str s))  = "<s>";

str unparse(strLength(CriteriaExpr expr))  = "length(<unparse(expr)>)";
str unparse(strToInt(CriteriaExpr expr))   = "toInt(<unparse(expr)>)";
str unparse(intToStr(CriteriaExpr expr))   = "toStr(<unparse(expr)>)";

str unparse(strConcat(list[CriteriaExpr] exprs)) = "<intercalate(" ++ ", [unparse(e) | e <- exprs])>";
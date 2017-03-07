module theories::relational::tests::binderTests::TransposeTester

extend theories::relational::tests::binderTests::TesterBase;

test bool transposeOfUnaryRelationIsItself() {
  Binding unary = t(["a"]) + t(["b"]);

  return transpose(unary) == unary;
}

test bool transposeOfBinary() {
  Binding binary = t(["a","b"]) + t(["a","c"]);
  
  return transpose(binary) == t(["b","a"]) + t(["c","a"]);
}

test bool tranposeOfTenary() {
  Binding tenary = t(["a","b","c"]) + t(["a","b","d"]);
  
  return transpose(tenary) == t(["c","b","a"]) + t(["d","b","a"]);
}
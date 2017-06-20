module smt::solver::SolverRunner

import smt::solver::Z3;

import List;
import String;
import Boolean;
import IO;
import Map;

alias SolverPID = int;

SolverPID startSolver() {
	pid = startZ3();
	
	// make sure that the unsatisfiable core are produced
	runSolver(pid, "(set-option :produce-unsat-cores true)");
	
	return pid;
}

void stopSolver(SolverPID pid) {
	stopZ3(pid);
}

bool isSatisfiable(SolverPID pid, str smtFormula) { 
  println("Starting to check satisfiability");
	str solverResult = runSolver(pid, smtFormula, wait=20); 
	if ("" !:= solverResult) {
		throw "Unable to assert clauses: <solverResult>"; 
	} 	
	
	return checkSat(pid);
}

bool checkSat(SolverPID pid) {
	switch(runSolver(pid, "(check-sat)", wait = 5)) {
		case "sat" : return true;
		case "unsat": return false;
		case "unknown": throw "Could not compute satisfiability";		
		default: throw "unable to get result from smt solver";
	}
}

str runSolver(SolverPID pid, str commands, int wait = 0) {
	try {
		return run(pid, commands, debug=false, wait = wait);
	}
	catch er: throw "Error while running SMT solver, reason: <er>"; 	
}

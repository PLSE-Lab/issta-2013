@license{
  Copyright (c) 2009-2012 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Mark Hills - Mark.Hills@cwi.nl (CWI)}
module lang::php::experiments::issta2013::ISSTA2013

import lang::php::util::Utils;
import lang::php::stats::Overall;
import lang::php::stats::Unfriendly;
import lang::php::util::Corpus;
import lang::php::ast::AbstractSyntax;
import lang::php::ast::System;
import lang::php::util::Config;
import lang::php::analysis::includes::IncludesInfo;
import lang::php::analysis::includes::QuickResolve;

import lang::rascal::types::AbstractType;

import IO;
import ValueIO;
import Type;
import List;
import Set;
import Map;
import DateTime;

import lang::csv::IO;
import Sizes = |csv+project://PHPAnalysis/src/lang/php/extract/csvs/linesPerFile.csv?funname=getLines|;

@doc{The corpus used in this experiment}
private Corpus issta13Corpus = (
	"osCommerce":"2.3.1",
	"ZendFramework":"1.11.12",
	"CodeIgniter":"2.1.2",
	"Symfony":"2.0.12",
	"SilverStripe":"2.4.7",
	"WordPress":"3.4",
	"Joomla":"2.5.4",
	"phpBB":"3",
	"Drupal":"7.14",
	"MediaWiki":"1.19.1",
	"Gallery":"3.0.4",
	"SquirrelMail":"1.4.22",
	"Moodle":"2.3",
	"Smarty":"3.1.11",
	"Kohana":"3.2",
	"phpMyAdmin":"3.5.0-english",
	"PEAR":"1.9.4",
	"CakePHP":"2.2.0-0",
	"DoctrineORM":"2.2.2");

public Corpus getISSTA2013Corpus() = issta13Corpus;

@doc{Parse all the corpus systems and save the ASTs}
public void buildCorpusBinaries(bool overwrite=false) {
	for (p <- issta13Corpus, v := issta13Corpus[p]) {
		if (!binaryExists(p,v) || overwrite) {
			buildBinaries(p,v);
		}
	}
}

@doc{Extract all the quick includes info (used by the quick includes process) for the corpus}
public void buildCorpusIncludesInfo() {
	for (p <- issta13Corpus, v := issta13Corpus[p]) {
		System sys = loadBinary(p,v);
		buildIncludesInfo(sys);
	}
}

@doc{The location where the includes info is stored}
private loc infoLoc = baseLoc + "serialized/quickResolved";

// TODO: This may be better placed in the logic for the quick resolve functionality
// so it can be reused in multiple analyses.
@doc{Extract the quick includes info for the given system product and version}
public void extractSystemQuickIncludes(str p, str v) {
	System sys = loadBinary(p,v);
	if (!includesInfoExists(p,v)) buildIncludesInfo(sys);
	IncludesInfo iinfo = loadIncludesInfo(p, v);
	rel[loc,loc,loc] res = { };
	map[loc,Duration] timings = ( );
	println("Resolving for <size(sys.files<0>)> files");
	counter = 0;
	for (l <- sys.files) {
		dt1 = now();
		qr = quickResolve(sys, iinfo, l, sys.baseLoc);
		dt2 = now();
		res = res + { < l, ll, lr > | < ll, lr > <- qr };
		counter += 1;
		if (counter % 100 == 0) {
			println("Resolved <counter> files");
		}
		timings[l] = (dt2 - dt1);
	}
	writeBinaryValueFile(infoLoc + "<p>-<v>-qr.bin", res);
	writeBinaryValueFile(infoLoc + "<p>-<v>-qrtime.bin", timings);
}

@doc{Extract the quick includes info for all systems in the corpus}
public void extractCorpusQuickIncludes() {
	for (p <- issta13Corpus, v := issta13Corpus[p]) {
		extractSystemQuickIncludes(p,v);
	}
}

@doc{Load all quick includes info for the corpus}
public map[tuple[str p, str v],rel[loc,loc,loc]] loadCorpusIncludes() {
	return ( <p,v> : readBinaryValueFile(#rel[loc,loc,loc], infoLoc + "<p>-<v>-qr.bin") |  p <- issta13Corpus, v := issta13Corpus[p] );
}

@doc{Load the feature map; generate it if it doesn't exist or user requests regeneration.}
private FMap loadOrGenerateFeatureMap(bool regenerateMap) {
	FMap fmap = ( );
	if (regenerateMap || !featsMapExists()) {
		fmap = getFMap();
		saveFeatsMap(fmap);
	} else {
		fmap = loadFeatsMap();
	}
	return fmap;
}

@doc{Load the feature lattice; generate it if it doesn't exist or user requests regeneration.}
private FeatureLattice loadOrGenerateFeatureLattice(bool regenerateLattice, FMap fmap) {
	FeatureLattice fl = { };
	if (regenerateLattice || !featureLatticeExists()) {
		fl = calculateFeatureLattice(fmap);
		saveFeatureLattice(fl);
	} else {
		fl = loadFeatureLattice();
	}
	return fl;
}

@doc{Load the coverage map; generate it if it doesn't exist or user requests regeneration.}
private CoverageMap loadOrGenerateCoverageMap(bool regenerateCoverageMap, FMap fmap, FeatureLattice fl) {
	CoverageMap coverageMap = ( );
	if (regenerateCoverageMap || !coverageMapExists()) {
		coverageMap = featuresForAllPercents(fmap, fl);
		saveCoverageMap(coverageMap);
	} else {
		coverageMap = loadCoverageMap();
	}
	return coverageMap;
}

@doc{Load the includes counts map; generate it if it doesn't exist or user requests regeneration.}
private ICResult loadOrGenerateIncludesCounts(bool regenerateIncludesCounts) {
	ICResult res = ( );
	if (regenerateIncludesCounts || !includesCountsExists()) {
		for (p <- issta13Corpus, v := issta13Corpus[p]) {
			System sys = loadBinary(p,v);
			if (!exists(infoLoc + "<p>-<v>-qr.bin")) {
				extractSystemQuickIncludes(p,v);
			}
			rel[loc,loc,loc] quickIncludes = readBinaryValueFile(#rel[loc,loc,loc], infoLoc + "<p>-<v>-qr.bin");
			countsTuple = calculateSystemIncludesCounts(sys, quickIncludes);
			res[<p,v>] = countsTuple;
		}
		saveIncludesCounts(res);
	} else {
		res = loadIncludesCounts();
	}
	
	return res;
}

@doc{Generate Table 1 from the ISSTA 2013 paper, which shows details of the corpus.}
public str generateTable1() {
	issta = getISSTA2013Corpus();
	return generateCorpusInfoTable(issta);
}

@doc{Generate Figure 1 from the ISSTA 2013 paper, which shows a histogram of file sizes.}
public str generateFigure1() {
	return fileSizesHistogram(getLines());
}

@doc{Generate Table 2 from the ISSTA 2013 paper, which shows which features are commonly used/not used in the corpus.}
public str generateTable2(bool regenerateMap=false, bool regenerateLattice=false) {
	FMap fmap = loadOrGenerateFeatureMap(regenerateMap);	
	FeatureLattice fl = loadOrGenerateFeatureLattice(regenerateLattice, fmap);

	fByPer = featuresForPercents(fmap,fl,[80,90,100]);
	labels = [ l | /label(l,_) := getMapRangeType((#FMap).symbol)];

	notIn80 = toSet(labels) - fByPer[80];
	notIn90 = toSet(labels) - fByPer[90];
	notIn100 = toSet(labels) - fByPer[100];
	
	return groupsTable(notIn80, notIn90, notIn100);
}

@doc{Generate Figure 2 from the ISSTA 2013 paper, which shows which feature groups appear in which percent of the files in the corpus.}
public str generateFigure2(bool regenerateMap=false) {
	FMap fmap = loadOrGenerateFeatureMap(regenerateMap);	

	return generalFeatureSquiglies(fmap);
}

@doc{Generate Figure 3 from the ISSTA 2013 paper, which shows the number of features needed to cover specific percentages of the corpus files.}
public str generateFigure3(bool regenerateMap=false, bool regenerateLattice=false, bool regenerateCoverageMap=false) {
	FMap fmap = loadOrGenerateFeatureMap(regenerateMap);	
	FeatureLattice fl = loadOrGenerateFeatureLattice(regenerateLattice, fmap);
	CoverageMap coverageMap = loadOrGenerateCoverageMap(regenerateCoverageMap, fmap, fl);

	return coverageGraph(coverageMap);
}

@doc{Generate Table 3 from the ISSTA 2013 paper, which shows how much of each corpus system is covered by the 80% and 90% feature sets.}
public str generateTable3(bool regenerateMap=false, bool regenerateLattice=false, bool regenerateCoverageMap=false) {
	issta = getISSTA2013Corpus();

	FMap fmap = loadOrGenerateFeatureMap(regenerateMap);	
	FeatureLattice fl = loadOrGenerateFeatureLattice(regenerateLattice, fmap);
	CoverageMap coverageMap = loadOrGenerateCoverageMap(regenerateCoverageMap, fmap, fl);

	ncm = notCoveredBySystem(issta, fl, coverageMap);
	return coverageComparison(issta,ncm);
}

@doc{Generate Table 4 from the ISSTA 2013 paper, which gives details on dynamic includes.}
public str generateTable4(bool regenerateCounts=false) {
	issta = getISSTA2013Corpus();
	icr = loadOrGenerateIncludesCounts(regenerateCounts);
	icounts = includeCounts(issta);
	return generateIncludeCountsTable(icr, icounts);
}

@doc{Generate Table 5 from the ISSTA 2013 paper, which gives details on variable features.}
public str generateTable5() {
	issta = getISSTA2013Corpus();
	corpusIncludes = loadCorpusIncludes();
	< vvuses, vvcalls, vvmcalls, vvnews, vvprops, vvcconsts, vvscalls, vvstargets, vvsprops, vvsptargets > = getAllVV(issta);
	trans = calculateVVTransIncludes(vvuses, vvcalls, vvmcalls, vvnews, vvprops, vvcconsts, vvscalls, vvstargets, vvsprops, vvsptargets, issta, corpusIncludes);
	return showVVInfoAsLatex(vvuses, vvcalls, vvmcalls, vvnews, vvprops,
		vvuses + vvcalls + vvmcalls + vvnews + vvprops + vvcconsts + vvscalls +
		vvstargets + vvsprops + vvsptargets, trans, issta);
}

@doc{Generate Table 6 from the ISSTA 2013 paper, which shows how many variable variables should be resolvable statically, based on manual inspection.}
public str generateTable6() {
	issta = getISSTA2013Corpus();
	return vvUsagePatternsTable(issta);
}

@doc{Generate Table 7 from the ISSTA 2013 paper, which gives details on magic methods.}
public str generateTable7() {
	issta = getISSTA2013Corpus();
	corpusIncludes = loadCorpusIncludes();	
	mmr = magicMethodUses(issta);
	trans = calculateMMTransIncludes(issta, mmr, corpusIncludes);
	return magicMethodCounts(issta, mmr, trans);
}

@doc{Generate Table 8 from the ISSTA 2013 paper, which gives details on eval and create_function.}
public str generateTable8() {
	issta = getISSTA2013Corpus();
	corpusIncludes = loadCorpusIncludes();	
	evalUses = corpusEvalUses(issta);
	transUses = calculateEvalTransIncludes(issta, evalUses, corpusIncludes);
	fuses = createFunctionUses(corpusFunctionUses(issta));
	ftransUses = calculateFunctionTransIncludes(issta, fuses, corpusIncludes);
	
	return evalCounts(issta, evalUses, fuses, transUses, ftransUses);
}

@doc{Generate Table 9 from the ISSTA 2013 paper, which gives details on varags functions.}
public str generateTable9() {
	rel[str,str,int] allCallsCounts = { };
	issta = getISSTA2013Corpus();
	corpusIncludes = loadCorpusIncludes();	
	for (p <- issta) {
		allcalls = allCalls(domainR(issta,{p}));
		allCallsCounts += < p, issta[p], size(allcalls) >;
	}
	vcalls = varargsCalls(issta);
	vdefs = varargsFunctionsAndMethods(issta);
	vcallsTrans = calculateFunctionTransIncludes(issta, vcalls<0,1,2,3>, corpusIncludes);
	return showVarArgsUses(issta, vdefs, vcalls, allCallsCounts, vcallsTrans);
}

@doc{Generate Table 10 from the ISSTA 2013 paper, which gives details on dynamic invocation.}
public str generateTable10() {
	issta = getISSTA2013Corpus();
	corpusIncludes = loadCorpusIncludes();	
	fuses = invokeFunctionUses(corpusFunctionUses(issta));
	ftrans = calculateFunctionTransIncludes(issta, fuses, corpusIncludes);
	return invokeFunctionUsesCounts(issta, fuses, ftrans);
}

// This generates all the tables and figures, but doesn't
// currently do anything with them. If you want to see them,
// the best way to do this is to run each of these lines in
// the console, then print the result, e.g.:
//		table1 = generateTable1();
//  	println(table1);
// or write it to a file, e.g.:
//      table1 = generateTable1();
//      writeFile(|file:///tmp/table1.txt|, table1);
public void main() {
	// Generate all the tables
	table1 = generateTable1();
	table2 = generateTable2();
	table3 = generateTable3();
	table4 = generateTable4();
	table5 = generateTable5();
	table6 = generateTable6();
	table7 = generateTable7();
	table8 = generateTable8();
	table9 = generateTable9();
	table10 = generateTable10();
	
	// Generate all the figures
	figure1 = generateFigure1();
	figure2 = generateFigure2();
	figure3 = generateFigure3();
}


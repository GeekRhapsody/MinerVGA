// Headless post-script: write every function's decompiled C, plus imports, exports and
// strings, to <output dir>/<program name>.c.
// Usage: analyzeHeadless ... -postScript ExportDecompilation.java <output dir>
// @category AfterDark

import java.io.File;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;

import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.data.StringDataInstance;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.Symbol;

public class ExportDecompilation extends GhidraScript {

	@Override
	protected void run() throws Exception {
		String[] args = getScriptArgs();
		File outDir = new File(args.length > 0 ? args[0] : ".");
		outDir.mkdirs();
		File out = new File(outDir, currentProgram.getName() + ".c");

		DecompInterface decomp = new DecompInterface();
		decomp.openProgram(currentProgram);
		int ok = 0, failed = 0;
		try (PrintWriter w = new PrintWriter(out, StandardCharsets.UTF_8)) {
			w.printf("// %s  sha256=%s  language=%s%n", currentProgram.getName(),
				currentProgram.getExecutableSHA256(), currentProgram.getLanguageID());

			w.println("// ---- external symbols (imports)");
			for (Symbol s : currentProgram.getSymbolTable().getExternalSymbols()) {
				w.printf("//   %s%n", s.getName(true));
			}
			w.println("// ---- entry points (exports)");
			for (var it = currentProgram.getSymbolTable().getExternalEntryPointIterator(); it.hasNext();) {
				var addr = it.next();
				Symbol s = currentProgram.getSymbolTable().getPrimarySymbol(addr);
				w.printf("//   %s %s%n", addr, s == null ? "?" : s.getName());
			}
			w.println("// ---- defined strings");
			for (Data d : currentProgram.getListing().getDefinedData(true)) {
				if (monitor.isCancelled()) {
					break;
				}
				if (StringDataInstance.isString(d)) {
					w.printf("//   %s %s%n", d.getAddress(), d.getDefaultValueRepresentation());
				}
			}

			for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
				if (monitor.isCancelled()) {
					break;
				}
				DecompileResults r = decomp.decompileFunction(f, 60, monitor);
				w.printf("%n// ==== %s @ %s%n", f.getName(), f.getEntryPoint());
				if (r != null && r.decompileCompleted()) {
					w.println(r.getDecompiledFunction().getC());
					ok++;
				}
				else {
					w.printf("// decompile failed: %s%n", r == null ? "null" : r.getErrorMessage());
					failed++;
				}
			}
		}
		finally {
			decomp.dispose();
		}
		println(String.format("ExportDecompilation: %s -> %s (%d ok, %d failed)",
			currentProgram.getName(), out, ok, failed));
	}
}

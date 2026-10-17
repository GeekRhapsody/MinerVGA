// Headless post-script: disassemble a segment range linearly and write the listing.
// Usage: analyzeHeadless ... -postScript ExportListing.java <out file> <start> <end>
//   e.g. ExportListing.java listing.txt 1000:0000 1000:9420
// Each line: address, bytes, instruction. Function starts and labels are marked so
// GOSUB targets stay visible even where Ghidra did not create a function.
// @category MinerVGA

import java.io.File;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;

import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSet;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.symbol.Symbol;

public class ExportListing extends GhidraScript {

	@Override
	protected void run() throws Exception {
		String[] args = getScriptArgs();
		File out = new File(args[0]);
		Address start = currentProgram.getAddressFactory().getAddress(args[1]);
		Address end = currentProgram.getAddressFactory().getAddress(args[2]);
		AddressSet range = new AddressSet(start, end);

		// Drop auto-analysis in the range (its function starts can split instructions),
		// then sweep linearly: start a disassembly at every undefined byte.
		for (Function f : currentProgram.getFunctionManager().getFunctions(range, true)) {
			removeFunction(f);
		}
		clearListing(start, end);
		Address a = start;
		while (a != null && a.compareTo(end) <= 0) {
			if (getInstructionContaining(a) == null && getDataContaining(a) == null) {
				new DisassembleCommand(a, range, true).applyTo(currentProgram, monitor);
			}
			Instruction ins = getInstructionContaining(a);
			a = ins == null ? a.add(1) : ins.getMaxAddress().add(1);
		}

		int n = 0;
		try (PrintWriter w = new PrintWriter(out, StandardCharsets.UTF_8)) {
			for (Instruction ins : currentProgram.getListing().getInstructions(range, true)) {
				Address at = ins.getAddress();
				Symbol s = currentProgram.getSymbolTable().getPrimarySymbol(at);
				if (s != null && s.getReferenceCount() > 0) {
					boolean called = false;
					for (var r : s.getReferences()) {
						called |= r.getReferenceType().isCall();
					}
					w.printf(called ? "%n;==== GOSUB %s%n" : "%s:%n", at.toString().replace("1000:", "L_"));
				}
				StringBuilder bytes = new StringBuilder();
				for (byte b : ins.getBytes()) {
					bytes.append(String.format("%02x", b & 0xff));
				}
				w.printf("%s  %-16s %s%n", at, bytes, ins);
				n++;
			}
		}
		println("ExportListing: " + n + " instructions -> " + out);
	}
}

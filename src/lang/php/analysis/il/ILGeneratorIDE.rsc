module lang::php::analysis::il::ILGeneratorIDE

import ParseTree;
import util::IDE;

public void setupIDE() {
	registerLanguage("ILGen", "ilg", Tree (str src, loc srcloc) {
		return parse(#ILGProgram, src);
	});
}
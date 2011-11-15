package lang.php.analysis.internal;

import java.util.Comparator;

import org.eclipse.imp.pdb.facts.IInteger;
import org.eclipse.imp.pdb.facts.IList;
import org.eclipse.imp.pdb.facts.INode;
import org.eclipse.imp.pdb.facts.IString;
import org.eclipse.imp.pdb.facts.IValue;

public class MemItemComparator implements Comparator<IValue> {

	private static final NamePathComparator npcomparator = new NamePathComparator();

	@Override
	public int compare(IValue o1, IValue o2) {
		INode c1 = (INode)o1;
		INode c2 = (INode)o2;
		
		int res = c1.getName().compareTo(c2.getName());
		if (res != 0) return res;
		
		if (c1.arity() > 0) {
			// TODO: Here we know that the fields are either ints or strings,
			// and that the ints are in a 32-bit bound. If either of these facts
			// changes this code will need to be modified.
			for (int idx = 0; idx < c1.arity(); ++idx) {
				if (c1.get(idx).getType().isStringType()) {
					res = ((IString)c1.get(idx)).compare((IString)c2.get(idx));
				} else if (c1.get(idx).getType().isIntegerType()) {
					res = ((IInteger)c1.get(idx)).compare((IInteger)c2.get(idx));
				} else {
					res = npcomparator.compare(c1.get(idx), c2.get(idx));
				}
				if (res != 0) return res;
			}
		}
		
		return 0;
	}

}

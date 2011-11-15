package lang.php.analysis.internal;

import java.util.Comparator;

import org.eclipse.imp.pdb.facts.INode;
import org.eclipse.imp.pdb.facts.IString;
import org.eclipse.imp.pdb.facts.IValue;

public class NamePartComparator implements Comparator<IValue> {

	@Override
	public int compare(IValue o1, IValue o2) {
		INode n1 = (INode)o1;
		INode n2 = (INode)o2;
		int res = n1.getName().compareTo(n2.getName());
		if (res != 0) return res;
		
		// TODO: This assumes that constructor names are not overloaded. If
		// they become overloaded, we need an extra check here to make sure
		// both have the same arity, plus we need to add code inside to check
		// various data types. At this point, we know that the arity is either
		// 0 or 1, and that, if the arity is 1, the data value is an IString.
		if (n1.arity() > 0) {
			res = ((IString)n1.get(0)).compare((IString)n2.get(0));
			if (res != 0) return res;
		}
		
		return 0;
	}

}

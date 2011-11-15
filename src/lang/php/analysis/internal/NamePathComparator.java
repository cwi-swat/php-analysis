package lang.php.analysis.internal;

import java.util.Comparator;

import org.eclipse.imp.pdb.facts.IList;
import org.eclipse.imp.pdb.facts.INode;
import org.eclipse.imp.pdb.facts.IString;
import org.eclipse.imp.pdb.facts.IValue;

public class NamePathComparator implements Comparator<IValue> {

	private static final NamePartComparator npcomparator = new NamePartComparator();
	
	@Override
	public int compare(IValue o1, IValue o2) {
		IList l1 = (IList)o1;
		IList l2 = (IList)o2;
		
		if (l1.length() < l2.length()) {
			return -1;
		} else if (l2.length() < l1.length()) {
			return 1;
		} else {
			for (int idx = 0; idx < l1.length(); ++idx) {
				int res = npcomparator.compare(l1.get(idx),l2.get(idx));
				if (res != 0) return res;
			}
		}
		
		return 0;
	}
	
}

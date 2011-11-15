package lang.php.analysis.internal;

import java.util.HashMap;

import org.eclipse.imp.pdb.facts.IBool;
import org.eclipse.imp.pdb.facts.IConstructor;
import org.eclipse.imp.pdb.facts.IInteger;
import org.eclipse.imp.pdb.facts.IMap;
import org.eclipse.imp.pdb.facts.IRelation;
import org.eclipse.imp.pdb.facts.ISet;
import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.IValueFactory;

public class ReferenceStructures {
	private final IValueFactory vf;
	private static HashMap<IInteger,SetValuedMap> setValuedMaps = new HashMap<IInteger,SetValuedMap>(); 
	private static int lastsvm = 0;
	
	public ReferenceStructures(IValueFactory vf) {
		this.vf = vf;
	}

	public IInteger makeSetValuedMap() {
		SetValuedMap svm = new SetValuedMap();
		setValuedMaps.put(vf.integer(lastsvm), svm);
		return vf.integer(lastsvm++);
	}
	
	public void addValue(IInteger svmid, IValue key, IValue v) {
		setValuedMaps.get(svmid).addValue(key, v);
	}

	public void addValues(IInteger svmid, IValue key, ISet sv) {
		setValuedMaps.get(svmid).addValues(key, sv);
	}
	
	public ISet getKeys(IInteger svmid, IConstructor domain) {
		return setValuedMaps.get(svmid).getKeys(domain);
	}

	public ISet getValues(IInteger svmid, IConstructor range, IValue key) {
		return setValuedMaps.get(svmid).getValues(range, key);
	}

	public IRelation asRelation(IInteger svmid, IConstructor domain, IConstructor range) {
		return setValuedMaps.get(svmid).asRelation(domain, range);
	}
	
	public void deleteSetValuedMap(IInteger svmid) {
		if (setValuedMaps.containsKey(svmid)) {
			setValuedMaps.remove(svmid);
		}
	}
	
	public IInteger getKeyCount(IInteger svmid) {
		return setValuedMaps.get(svmid).getKeyCount();
	}
	
	public IInteger getValueCount(IInteger svmid) {
		return setValuedMaps.get(svmid).getValueCount();
	}
	
	public IBool removeValuesForKey(IInteger svmid, IValue key) {
		return setValuedMaps.get(svmid).removeValuesForKey(key);
	}
	
	public IBool removeValueForKey(IInteger svmid, IValue key, IValue value) {
		return setValuedMaps.get(svmid).removeValueForKey(key,value);
	}
	
	public IMap getKeyCountMap(IInteger svmid, IConstructor domain) {
		return setValuedMaps.get(svmid).getKeyCountMap(domain);
	}
	
}

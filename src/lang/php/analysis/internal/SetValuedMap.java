package lang.php.analysis.internal;

import java.util.Iterator;
import java.util.TreeMap;
import java.util.TreeSet;

import org.eclipse.imp.pdb.facts.IBool;
import org.eclipse.imp.pdb.facts.IConstructor;
import org.eclipse.imp.pdb.facts.IInteger;
import org.eclipse.imp.pdb.facts.IMap;
import org.eclipse.imp.pdb.facts.IMapWriter;
import org.eclipse.imp.pdb.facts.IRelation;
import org.eclipse.imp.pdb.facts.IRelationWriter;
import org.eclipse.imp.pdb.facts.ISet;
import org.eclipse.imp.pdb.facts.ISetWriter;
import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.type.Type;
import org.eclipse.imp.pdb.facts.type.TypeFactory;
import org.eclipse.imp.pdb.facts.type.TypeStore;
import org.rascalmpl.interpreter.Typeifier;
import org.rascalmpl.interpreter.types.ReifiedType;
import org.rascalmpl.values.ValueFactoryFactory;

public class SetValuedMap {

	private static final NamePathComparator namePathComparator = new NamePathComparator();
	
	private TreeMap<IValue,TreeSet<IValue>> internalMap;

	public SetValuedMap() {
		internalMap = new TreeMap<IValue,TreeSet<IValue>>(namePathComparator);
	}
	
	public void addValue(IValue key, IValue v) {
		if (!this.internalMap.containsKey(key))
			this.internalMap.put(key, new TreeSet<IValue>(namePathComparator));
		this.internalMap.get(key).add(v);
	}
	
	public void addValues(IValue key, ISet vs) {
		if (!this.internalMap.containsKey(key))
			this.internalMap.put(key, new TreeSet<IValue>(namePathComparator));
		Iterator<IValue> iter = vs.iterator();
		while (iter.hasNext()) addValue(key, iter.next());
	}
	
	public IBool removeValuesForKey(IValue key) {
		if (this.internalMap.containsKey(key)) {
			this.internalMap.remove(key);
			return ValueFactoryFactory.getValueFactory().bool(true);
		}
		return ValueFactoryFactory.getValueFactory().bool(false);
	}

	public IBool removeValueForKey(IValue key, IValue value) {
		if (this.internalMap.containsKey(key)) {
			if (this.internalMap.get(key).remove(value)) {
				return ValueFactoryFactory.getValueFactory().bool(true);
			}
		}
		return ValueFactoryFactory.getValueFactory().bool(false);
	}

	public ISet getKeys(IConstructor domainType) {
		Type domain = ((ReifiedType) domainType.getType()).getTypeParameters().getFieldType(0);
		TypeStore store = new TypeStore();
		Typeifier.declare(domainType, store);
		Type itemType = TypeFactory.getInstance().aliasType(store, "NamePath", 
								TypeFactory.getInstance().listType(
										TypeFactory.getInstance().abstractDataType(store, domain.getName())));
		ISetWriter sw = ValueFactoryFactory.getValueFactory().setWriter(itemType);
		for (IValue v : this.internalMap.keySet())
			sw.insert(v);
		return sw.done();
	}
	
	public ISet getValues(IConstructor rangeType, IValue key) {
		Type range = ((ReifiedType) rangeType.getType()).getTypeParameters().getFieldType(0);
		TypeStore store = new TypeStore();
		Typeifier.declare(rangeType, store);
		Type itemType = TypeFactory.getInstance().aliasType(store, "NamePath", 
								TypeFactory.getInstance().listType(
										TypeFactory.getInstance().abstractDataType(store, range.getName())));
		ISetWriter sw = ValueFactoryFactory.getValueFactory().setWriter(itemType);
		if (this.internalMap.containsKey(key)) {
			for (IValue v : this.internalMap.get(key))
				sw.insert(v);
		}
		return sw.done();
	}
	
	public IRelation asRelation(IConstructor domainType, IConstructor rangeType) {
		// TODO: Declare once -- this assumes they are the same type...
		TypeStore store = new TypeStore();
		Type domain = ((ReifiedType) domainType.getType()).getTypeParameters().getFieldType(0);
		Typeifier.declare(domainType, store);
		Type itemType = TypeFactory.getInstance().aliasType(store, "NamePath", 
								TypeFactory.getInstance().listType(
										TypeFactory.getInstance().abstractDataType(store, domain.getName())));
		Type tupleType = TypeFactory.getInstance().tupleType(itemType, itemType);
		
		IRelationWriter rw = ValueFactoryFactory.getValueFactory().relationWriter(tupleType);
		
		for (IValue domainValue : this.internalMap.keySet()) {
			for (IValue rangeValue : this.internalMap.get(domainValue)) {
				rw.insert(ValueFactoryFactory.getValueFactory().tuple(domainValue, rangeValue));
			}
		}
		return rw.done();
	}
	
	public IInteger getKeyCount() {
		return ValueFactoryFactory.getValueFactory().integer(this.internalMap.size());
	}
	
	public IInteger getValueCount() {
		IInteger res = ValueFactoryFactory.getValueFactory().integer(0);
		for (IValue v : this.internalMap.keySet())
			res = res.add(ValueFactoryFactory.getValueFactory().integer(this.internalMap.get(v).size()));
		return res;
	}
	
	public IMap getKeyCountMap(IConstructor domainType) {
		TypeStore store = new TypeStore();
		Type domain = ((ReifiedType) domainType.getType()).getTypeParameters().getFieldType(0);
		Typeifier.declare(domainType, store);
		Type keyType = TypeFactory.getInstance().aliasType(store, "NamePath", 
								TypeFactory.getInstance().listType(
										TypeFactory.getInstance().abstractDataType(store, domain.getName())));
		Type valueType = TypeFactory.getInstance().integerType();
		
		IMapWriter mw = ValueFactoryFactory.getValueFactory().mapWriter(keyType, valueType);
		for (IValue v : this.internalMap.keySet()) {
			mw.put(v, ValueFactoryFactory.getValueFactory().integer(this.internalMap.get(v).size()));
		}
		return mw.done();
	}
}

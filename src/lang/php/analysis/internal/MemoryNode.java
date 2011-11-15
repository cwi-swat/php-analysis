package lang.php.analysis.internal;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.TreeMap;
import java.util.TreeSet;

import org.eclipse.imp.pdb.facts.IBool;
import org.eclipse.imp.pdb.facts.IConstructor;
import org.eclipse.imp.pdb.facts.IInteger;
import org.eclipse.imp.pdb.facts.IList;
import org.eclipse.imp.pdb.facts.INode;
import org.eclipse.imp.pdb.facts.IRelation;
import org.eclipse.imp.pdb.facts.IRelationWriter;
import org.eclipse.imp.pdb.facts.ISet;
import org.eclipse.imp.pdb.facts.ISetWriter;
import org.eclipse.imp.pdb.facts.IString;
import org.eclipse.imp.pdb.facts.ITuple;
import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.type.Type;
import org.eclipse.imp.pdb.facts.type.TypeFactory;
import org.eclipse.imp.pdb.facts.type.TypeStore;
import org.rascalmpl.interpreter.Typeifier;
import org.rascalmpl.interpreter.types.ReifiedType;
import org.rascalmpl.values.ValueFactoryFactory;

public class MemoryNode implements Cloneable {
	/** Children of the current memory node */
	private TreeMap<IValue, MemoryNode> children;
	
	/** Items held at this memory node */
	private TreeSet<IValue> items;
	
	/** Global cache of object items */
	private static HashMap<IValue, MemoryNode> objectItems = new HashMap<IValue, MemoryNode>();
	
	/** Global cache of field information on different classes */
	private static IRelation fieldRelation = null;

	private static final MemItemComparator memItemComparator = new MemItemComparator();
	private static final NamePartComparator namePartComparator = new NamePartComparator();
	
	/**
	 * Construct a default empty memory node.
	 */
	public MemoryNode() {
		this.children = null;
		this.items = null;
	}
	
	/**
	 * Set the field relation, which can then be used below in the code.
	 * 
	 * TODO: This should be stored elsewhere, since it varies between memory
	 * 		 nodes. We can currently get away with this because we are only
	 *       building one at a time.
	 */
	public void setFieldRelation(IRelation fr) {
		MemoryNode.fieldRelation = fr;
	}
	
	/**
	 * Add the set of items given in items to the node(s) indicated by path.
	 * We can have multiple reachable nodes in the case where the path
	 * includes a field, since this field could be on multiple objects.
	 * 
	 * @param path 		The path to the child(ren) that we wish to add the items to.
	 * @param items 	The items we wish to add.
	 */
	public void addItems(IList path, ISet items) {
		for (MemoryNode mn : getNodeCreatePath(path)) {
			if (mn.items == null) mn.items = new TreeSet<IValue>(memItemComparator);
			Iterator<IValue> iter = items.iterator();
			while (iter.hasNext()) {
				// If we are inserting an object, merge this with the information
				// contained in the other objects.
				IConstructor item = (IConstructor)iter.next();
				if (item.getConstructorType().getName().equals("objectVal")) {
					if (!MemoryNode.objectItems.containsKey(item)) {
						MemoryNode.objectItems.put(item, new MemoryNode());
					}
					
					if (mn.items != null) {
						for (IValue item2v : mn.items) {
							IConstructor item2 = (IConstructor)item2v;
							if (item2.getConstructorType().getName().equals("objectVal")) {
								MemoryNode mn1 = MemoryNode.objectItems.get(item);
								MemoryNode mn2 = MemoryNode.objectItems.get(item2);
								mn1.mergeNode(mn2);
								MemoryNode.objectItems.put(item2, mn1);
								break;
							}
						}
					}
				}
				mn.items.add(item);
			}
		}
	}

	/**
	 * Retrieve the items available at the given path.
	 * 
	 * @param path		The path to the child(ren) that we with to get the items from.
	 * @return			The items set reachable along this path.
	 * 
	 * TODO: This only works if the type is not parameterized.
	 */
	public ISet getItems(IList path, IConstructor type) {
		Type storeItem = ((ReifiedType) type.getType()).getTypeParameters().getFieldType(0);
		TypeStore store = new TypeStore();
		Typeifier.declare(type, store);
		
		ISetWriter sw = ValueFactoryFactory.getValueFactory().setWriter(TypeFactory.getInstance().abstractDataType(store, storeItem.getName()));
		for (MemoryNode mn : getNodeCreatePath(path)) {
			if (mn.items != null) {
				for (IValue item : mn.items) {
					sw.insert(item);
				}
			}
		}
		return sw.done();			
	}
	
	/**
	 * Merge the contents of the source node into the current node, returning
	 * whether this actually changed the node (or not).
	 * 
	 * @param source	The node whose contents we wish to merge into this node.
	 * @return			True if the merge made any changes, false otherwise.
	 */
	public IBool mergeNode(MemoryNode source) {
		IBool haveModified = ValueFactoryFactory.getValueFactory().bool(false);
		
		if (source.items != null) {
			if (this.items == null) {
				this.items = new TreeSet<IValue>(memItemComparator);
				this.items.addAll(source.items);
				haveModified = ValueFactoryFactory.getValueFactory().bool(true);
			} else {
				if (! this.items.containsAll(source.items)) {
					this.items.addAll(source.items);
					haveModified = ValueFactoryFactory.getValueFactory().bool(true);
				}
			}
		}

		if (source.children != null) {
			if (this.children == null) {
				this.children = new TreeMap<IValue,MemoryNode>(namePartComparator);
				for (IValue child : source.children.keySet()) {
					try {
						this.children.put(child, (MemoryNode)source.children.get(child).clone());
					} catch (CloneNotSupportedException e) {
						// TODO: Throw a Rascal exception here...
						e.printStackTrace();
					}
				}
				haveModified = ValueFactoryFactory.getValueFactory().bool(true);
			} else {
				for (IValue child : source.children.keySet()) {
					if (this.children.containsKey(child)) {
						haveModified = haveModified.or(this.children.get(child).mergeNode(source.children.get(child)));
					} else {
						try {
							this.children.put(child, (MemoryNode)source.children.get(child).clone());
							haveModified = ValueFactoryFactory.getValueFactory().bool(true);
						} catch (CloneNotSupportedException e) {
							// TODO: Throw a Rascal exception here...
							e.printStackTrace();
						}
					}
				}
			}
		}
		
		return haveModified;
	}

	/**
	 * Check whether the given path leads to at least one existing node.
	 * We consider this to be true when we can reach a node that has items
	 * associated with it (otherwise the node was just created as we checked
	 * along the path).
	 * 
	 * @param childId	The path to the node(s).
	 * 
	 * @return			true if at least one node is reachable on this path,
	 * 					false otherwise
	 */
	public IBool hasNode(IList path) {
		if(getNode(path).size() > 0) {
			return ValueFactoryFactory.getValueFactory().bool(true);
		}
		return ValueFactoryFactory.getValueFactory().bool(false);
	}
	
	/**
	 * Get the node(s) at the given path, but does not attempt to create a
	 * path to the node.
	 * 
	 * @param path		The path to the node.
	 * 
	 * @return			The node(s) indicated by the path. There can be
	 *                  multiple nodes if the path goes through an object
	 *                  with fields.
	 */
	public HashSet<MemoryNode> getNode(IList path) {
		HashSet<MemoryNode> res = new HashSet<MemoryNode>(1);

		if (path.length() == 0) {
			res.add(this);
		} else {
			IConstructor pathPart = (IConstructor)path.get(0);
			path = path.sublist(1, path.length() - 1);
			
			// Is this path part a field? If so, we need to look in any objects to find
			// the memory nodes pointed to by the fields.
			if (pathPart.getConstructorType().getName().equals("field")) {
				INode fieldAsNode = (INode)pathPart;
				IString fieldName = (IString)fieldAsNode.get(0);
				if (this.items != null) {
					for (IValue itemv : this.items) {
						IConstructor item = (IConstructor)itemv;
						if (item.getConstructorType().getName().equals("objectVal")) {
							INode itemAsNode = (INode)item;
							IString className = (IString)itemAsNode.get(0);
							ITuple cfTuple = ValueFactoryFactory.getValueFactory().tuple(className,fieldName);
							if (MemoryNode.fieldRelation.contains(cfTuple)) {
								MemoryNode objectNode = MemoryNode.objectItems.get(item);
								if (objectNode.children != null && objectNode.children.containsKey(pathPart))
									res.addAll(objectNode.children.get(pathPart).getNodeCreatePath(path));
							}
						}
					}
				}
			} else {
				if (this.children != null && this.children.containsKey(pathPart))
					res.addAll(this.children.get(pathPart).getNode(path));
			}
		}
		return res;
	}

	/**
	 * Get the node(s) at the given path, creating the path if needed.
	 * 
	 * @param path		The path to the node.
	 * 
	 * @return			The node(s) indicated by the path. There can be
	 *                  multiple nodes if the path goes through an object
	 *                  with fields.
	 */
	public HashSet<MemoryNode> getNodeCreatePath(IList path) {
		HashSet<MemoryNode> res = new HashSet<MemoryNode>(1);

		if (path.length() == 0) {
			res.add(this);
		} else {
			IConstructor pathPart = (IConstructor)path.get(0);
			path = path.sublist(1, path.length() - 1);
			
			// Is this path part a field? If so, we need to look in any objects to find
			// the memory nodes pointed to by the fields.
			if (pathPart.getConstructorType().getName().equals("field")) {
				INode fieldAsNode = (INode)pathPart;
				IString fieldName = (IString)fieldAsNode.get(0);
				if (this.items != null) {
					for (IValue itemv : this.items) {
						IConstructor item = (IConstructor)itemv;
						if (item.getConstructorType().getName().equals("objectVal")) {
							INode itemAsNode = (INode)item;
							IString className = (IString)itemAsNode.get(0);
							ITuple cfTuple = ValueFactoryFactory.getValueFactory().tuple(className,fieldName);
							if (MemoryNode.fieldRelation.contains(cfTuple)) {
								MemoryNode objectNode = MemoryNode.objectItems.get(item);
								if (objectNode.children == null)
										objectNode.children = new TreeMap<IValue,MemoryNode>(namePartComparator);
								if (!objectNode.children.containsKey(pathPart))
									objectNode.children.put(pathPart, new MemoryNode());
								res.addAll(objectNode.children.get(pathPart).getNodeCreatePath(path));
							}
						}
					}
				}
			} else {
				if (this.children == null)
					this.children = new TreeMap<IValue,MemoryNode>(namePartComparator);
				if (!this.children.containsKey(pathPart)) {
					this.children.put(pathPart, new MemoryNode());
				}
				res.addAll(this.children.get(pathPart).getNodeCreatePath(path));
			}
		}
		return res;
	}

	private void collapseInternal(IRelationWriter rw, IList path) {
		if (this.items != null && this.items.size() > 0) {
			for (IValue itemv : this.items) {
				rw.insert(ValueFactoryFactory.getValueFactory().tuple(path,itemv));
				IConstructor item = (IConstructor)itemv;
				if (item.getConstructorType().getName().equals("objectVal")) {
					MemoryNode objectItem = MemoryNode.objectItems.get(item);
					INode itemAsNode = (INode)item;
					IString className = (IString)itemAsNode.get(0);

					if (objectItem.children != null && objectItem.children.size() > 0) {
						for (IValue child : objectItem.children.keySet()) {
							INode fieldAsNode = (INode)child;
							IString fieldName = (IString)fieldAsNode.get(0);
							ITuple cfTuple = ValueFactoryFactory.getValueFactory().tuple(className,fieldName);
							if (MemoryNode.fieldRelation.contains(cfTuple)) {
								objectItem.children.get(child).collapseInternal(rw, path.append(child));
							}
						}
					}
				}
			}
		}
		
		if (this.children != null && this.children.size() > 0) {
			for (IValue child : this.children.keySet()) {
				this.children.get(child).collapseInternal(rw, path.append(child));
			}
		}
	}
	
	public IRelation collapseToRelation(IList path, IConstructor left, IConstructor right) {
		TypeStore store = new TypeStore();

		Type leftItem = ((ReifiedType) left.getType()).getTypeParameters().getFieldType(0);
		Typeifier.declare(left, store);

		Type rightItem = ((ReifiedType) right.getType()).getTypeParameters().getFieldType(0);
		Typeifier.declare(right, store);		
		
		Type tupleItem = TypeFactory.getInstance().tupleType(
				TypeFactory.getInstance().aliasType(store, "NamePath", 
						TypeFactory.getInstance().listType(
								TypeFactory.getInstance().abstractDataType(store, leftItem.getName()))), 
				TypeFactory.getInstance().abstractDataType(store, rightItem.getName()));
		IRelationWriter rw = ValueFactoryFactory.getValueFactory().relationWriter(tupleItem);

		collapseInternal(rw,path);
		
		return rw.done();
	}

	@SuppressWarnings("unchecked")
	@Override
	protected Object clone() throws CloneNotSupportedException {
		MemoryNode newNode = new MemoryNode();
		if (this.items != null) {
			newNode.items = new TreeSet<IValue>(memItemComparator);
			newNode.items = (TreeSet<IValue>)this.items.clone();
		}
		if (this.children != null) {
			newNode.children = new TreeMap<IValue,MemoryNode>(namePartComparator);
			for (IValue child : this.children.keySet()) {
				newNode.children.put(child, (MemoryNode)children.get(child).clone());
			}
		}
		return newNode;
	}
	
	private IInteger getNodeCountInternal() {
		IInteger res = ValueFactoryFactory.getValueFactory().integer(1);
		if (this.children != null) {
			for (IValue v : this.children.keySet()) {
				res = res.add(this.children.get(v).getNodeCountInternal());
			}
		}
		return res;
	}

	public IInteger getNodeCount() {
		IInteger res = this.getNodeCountInternal();
		HashSet<MemoryNode> objectValues = new HashSet<MemoryNode>(MemoryNode.objectItems.values());
		for (MemoryNode mn : objectValues)
			res = res.add(mn.getNodeCountInternal());
		return res;
	}
	
	public IInteger getObjectCount() {
		return ValueFactoryFactory.getValueFactory().integer(MemoryNode.objectItems.keySet().size());
	}
	
	public IInteger getObjectChildCount() {
		IInteger res = ValueFactoryFactory.getValueFactory().integer(0);
		for (IValue v : MemoryNode.objectItems.keySet()) {
			if (MemoryNode.objectItems.get(v).children != null) {
				res = res.add(ValueFactoryFactory.getValueFactory().integer(MemoryNode.objectItems.get(v).children.size()));
			}
		}
		return res;
	}
	
	private IInteger getItemCountInternal() {
		IInteger res = ValueFactoryFactory.getValueFactory().integer(0);
		if (this.items != null)
			res = res.add(ValueFactoryFactory.getValueFactory().integer(this.items.size()));
		if (this.children != null) {
			for (IValue v : this.children.keySet()) {
				res = res.add(this.children.get(v).getItemCountInternal());
			}
		}
		return res;
	}

	public IInteger getItemCount() {
		IInteger res = this.getItemCountInternal();
		HashSet<MemoryNode> objectValues = new HashSet<MemoryNode>(MemoryNode.objectItems.values());
		for (MemoryNode mn : objectValues)
			res = res.add(mn.getItemCountInternal());
		return res;
	}

	//	@SuppressWarnings("unchecked")
//	private boolean checkForCyclesInternal(TreeSet<MemoryNode> hs) {
//		if (hs.contains(this)) return true;
//		
//		hs.add(this);
//		TreeSet<MemoryNode> beforeDescent = (TreeSet<MemoryNode>)hs.clone();
//		boolean res = false;
//
//		for (IValue child : this.children.keySet()) {
//			if(this.children.get(child).checkForCyclesInternal(hs))
//				res = true;
//			hs = (TreeSet<MemoryNode>)beforeDescent.clone();
//			if (res) break;
//		}
//		
//		hs.remove(this);
//		return res;
//	}
//	
//	public IBool checkForCycles() {
//		boolean res = checkForCyclesInternal(new TreeSet<MemoryNode>());
//		return ValueFactoryFactory.getValueFactory().bool(res);
//	}
//	
//	private LinkedList<IValue> findDeepestPathInternal(int depthSoFar) {
//		LinkedList<IValue> deepest = new LinkedList<IValue>();
//		IValue deepestChild = null;
//		
//		System.out.println("Entered findDeepestPathInternal");
//		
//		if (depthSoFar > 50) {
//			System.out.println("WARNING: Depth has grown to over 50, truncating");
//			return deepest;
//		}
//		
//		for (IValue child : children.keySet()) {
//			LinkedList<IValue> childDepth = children.get(child).findDeepestPathInternal(depthSoFar+1);
//			if (childDepth.size() >= deepest.size()) {
//				deepest = childDepth;
//				deepestChild = child;
//				System.out.println("Found deepest child, storing...");
//			}
//		}
//		
//		if (deepestChild != null)
//			deepest.push(deepestChild);
//
//		System.out.println("Exiting, deepest has length " + Integer.toString(deepest.size()));
//		return deepest;
//	}
//	
//	public IList findDeepestPath() {
//		LinkedList<IValue> deepest = findDeepestPathInternal(1);
//		IListWriter lw = ValueFactoryFactory.getValueFactory().listWriter(TypeFactory.getInstance().valueType());
//		for (IValue iv : deepest) lw.append(iv);
//		return lw.done();
//	}
}

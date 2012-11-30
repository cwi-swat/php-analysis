package lang.php.analysis.internal;

import java.util.HashMap;

import org.eclipse.imp.pdb.facts.IBool;
import org.eclipse.imp.pdb.facts.IConstructor;
import org.eclipse.imp.pdb.facts.IInteger;
import org.eclipse.imp.pdb.facts.IList;
import org.eclipse.imp.pdb.facts.IRelation;
import org.eclipse.imp.pdb.facts.ISet;
import org.eclipse.imp.pdb.facts.IValueFactory;

public class MemoryModel {
	private final IValueFactory vf;
	private static HashMap<IInteger,MemoryNode> memoryNodes = new HashMap<IInteger,MemoryNode>(); 
	private static int lastNodeId = 0;
	
	public MemoryModel(IValueFactory vf) {
		this.vf = vf;
	}
	
	public IInteger makeRootNode(IRelation r) {
		MemoryNode mn = new MemoryNode();
		mn.setFieldRelation(r);
		memoryNodes.put(vf.integer(lastNodeId), mn);
		return vf.integer(lastNodeId++);
	}
	
	public void addItems(IInteger memoryNode, IList namePath, ISet valuesToAdd) {
		memoryNodes.get(memoryNode).addItems(namePath, valuesToAdd);
	}
	
	public ISet getItems(IInteger memoryNode, IList namePath, IConstructor type) {
		return memoryNodes.get(memoryNode).getItems(namePath, type);
	}
	
	public IBool hasNode(IInteger memoryNode, IList namePath) {
		return memoryNodes.get(memoryNode).hasNode(namePath);
	}
	
	public IBool mergeNodes(IInteger memoryNode, IList sourcePath, IList targetPath) {
		MemoryNode rootNode = memoryNodes.get(memoryNode);
		IBool res = ValueFactoryFactory.getValueFactory().bool(false);
		for (MemoryNode sourceNode : rootNode.getNodeCreatePath(sourcePath)) {
			for (MemoryNode targetNode : rootNode.getNodeCreatePath(targetPath)) {
				res = res.or(targetNode.mergeNode(sourceNode));
			}
		}
		return res;
	}
	
	public void deleteRootNode(IInteger memoryNode) {
		if (memoryNodes.containsKey(memoryNode)) {
			memoryNodes.remove(memoryNode);
		}
	}
	
	public IRelation collapseToRelation(IInteger memoryNode, IList namePath, IConstructor left, IConstructor right) {
		return memoryNodes.get(memoryNode).collapseToRelation(namePath, left, right);
	}
	
	public IInteger getNodeCount(IInteger memoryNode) {
		return memoryNodes.get(memoryNode).getNodeCount();
	}
	
	public IInteger getObjectCount(IInteger memoryNode) {
		return memoryNodes.get(memoryNode).getObjectCount();
	}

	public IInteger getObjectChildCount(IInteger memoryNode) {
		return memoryNodes.get(memoryNode).getObjectChildCount();
	}

	public IInteger getItemCount(IInteger memoryNode) {
		return memoryNodes.get(memoryNode).getItemCount();
	}

	//	public IBool checkForCycles(IInteger memoryNode) {
//		return memoryNodes.get(memoryNode).checkForCycles();
//	}
//
//	public IList findDeepestPath(IInteger memoryNode) {
//		return memoryNodes.get(memoryNode).findDeepestPath();
//	}
}

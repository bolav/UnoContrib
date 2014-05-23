/*
* Box2D.XNA port of Box2D:
* Copyright (c) 2009 Brandon Furtwangler, Nathan Furtwangler
*
* Original source Box2D:
* Copyright (c) 2006-2009 Erin Catto http://www.gphysics.com
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
*/

using Uno.Collections;

namespace Uno.Physics.Box2D
{
    /// A dynamic AABB tree broad-phase, inspired by Nathanael Presson's btDbvt.

    internal delegate float RayCastCallbackInternal(ref RayCastInput input, int userData);

    /// A box2dNode in the dynamic tree. The client does not interact with this directly.
    internal struct DynamicTreeNode
    {
        internal bool IsLeaf()
	    {
		    return child1 == DynamicTree.NullNode;
	    }

        /// This is the fattened AABB.
	    internal AABB aabb;

        internal object userData;

        internal int parentOrNext;
        internal int child1;
        internal int child2;

        internal int leafCount;
    }

    /// A dynamic tree arranges data in a binary tree to accelerate
    /// queries such as volume queries and ray casts. Leafs are proxies
    /// with an AABB. In the tree we expand the proxy AABB by Settings.b2_fatAABBFactor
    /// so that the proxy AABB is bigger than the client object. This allows the client
    /// object to move by small amounts without triggering a tree update.
    ///
    /// Nodes are pooled and relocatable, so we use box2dNode indices rather than pointers.
    public class DynamicTree
    {
        internal static int NullNode = -1;

	    /// ructing the tree initializes the box2dNode pool.
	    public DynamicTree()
        {
	        _root = NullNode;

	        _box2dNodeCapacity = 16;
	        _box2dNodeCount = 0;
	        _box2dNodes = new DynamicTreeNode[_box2dNodeCapacity];

	        // Build a linked list for the free list.
	        for (int i = 0; i < _box2dNodeCapacity - 1; ++i)
	        {
                _box2dNodes[i].parentOrNext = i + 1;
	        }
            _box2dNodes[_box2dNodeCapacity - 1].parentOrNext = NullNode;
	        _freeList = 0;

	        _path = 0;
        }

	    /// Create a proxy. Provide a tight fitting AABB and a userData pointer.
	    public int CreateProxy(ref AABB aabb, object userData)
        {
	        int proxyId = AllocateNode();

	        // Fatten the aabb.
            float2 r = float2(Settings.b2_aabbExtension, Settings.b2_aabbExtension);
	        _box2dNodes[proxyId].aabb.lowerBound = aabb.lowerBound - r;
	        _box2dNodes[proxyId].aabb.upperBound = aabb.upperBound + r;
	        _box2dNodes[proxyId].userData = userData;
            _box2dNodes[proxyId].leafCount = 1;

	        InsertLeaf(proxyId);

            // Rebalance if necessary.
            int iterationCount = _box2dNodeCount >> 4;
            int tryCount = 0;
            int height = ComputeHeight();
            while (height > 64 && tryCount < 10)
            {
                Rebalance(iterationCount);
                height = ComputeHeight();
                ++tryCount;
            }

	        return proxyId;
        }

	    /// Destroy a proxy. This asserts if the id is invalid.
	    public void DestroyProxy(int proxyId)
        {
	        RemoveLeaf(proxyId);
	        FreeNode(proxyId);
        }

        /// Move a proxy with a swepted AABB. If the proxy has moved outside of its fattened AABB,
	    /// then the proxy is removed from the tree and re-inserted. Otherwise
	    /// the function returns immediately.
        /// @return true if the proxy was re-inserted.
	    public bool MoveProxy(int proxyId, ref AABB aabb, float2 displacement)
        {
	        if (_box2dNodes[proxyId].aabb.Contains(ref aabb))
	        {
		        return false;
	        }

	        RemoveLeaf(proxyId);

            // Extend AABB.
            AABB b = aabb;

	        float2 r = float2(Settings.b2_aabbExtension, Settings.b2_aabbExtension);
            b.lowerBound = b.lowerBound - r;
            b.upperBound = b.upperBound + r;

            // Predict AABB displacement.
            float2 d = Settings.b2_aabbMultiplier * displacement;

            if (d.X < 0.0f)
            {
                b.lowerBound.X += d.X;
            }
            else
            {
                b.upperBound.X += d.X;
            }

            if (d.Y < 0.0f)
            {
                b.lowerBound.Y += d.Y;
            }
            else
            {
                b.upperBound.Y += d.Y;
            }

            _box2dNodes[proxyId].aabb = b;

	        InsertLeaf(proxyId);

            return true;
        }

	    /// Perform some iterations to re-balance the tree.
	    public void Rebalance(int iterations)
        {
	        if (_root == NullNode)
	        {
		        return;
	        }

	        for (int i = 0; i < iterations; ++i)
	        {
		        int box2dNode = _root;

		        int bit = 0;
		        while (_box2dNodes[box2dNode].IsLeaf() == false)
		        {
			        // Child selector based on a bit in the path
			        int selector = (_path >> bit) & 1;

			        // Select the child nod
			        box2dNode = (selector == 0) ? _box2dNodes[box2dNode].child1 : _box2dNodes[box2dNode].child2;

			        // Keep bit between 0 and 31 because _path has 32 bits
			        // bit = (bit + 1) % 31
			        bit = (bit + 1) & 0x1F;
		        }
		        ++_path;

		        RemoveLeaf(box2dNode);
		        InsertLeaf(box2dNode);
	        }
        }

	    /// Get proxy user data.
	    /// @return the proxy user data or 0 if the id is invalid.
	    public object GetUserData(int proxyId)
        {
		    return _box2dNodes[proxyId].userData;
        }

	    /// Get the fat AABB for a proxy.
        public void GetFatAABB(int proxyId, out AABB fatAABB)
        {
	        fatAABB = _box2dNodes[proxyId].aabb;
        }

        /// Compute the height of the binary tree in O(N) time. Should not be
        /// called often.
	    public int ComputeHeight()
        {
	        return ComputeHeight(_root);
        }

        static List<int> stack = new List<int>();

	    /// Query an AABB for overlapping proxies. The callback class
	    /// is called for each proxy that overlaps the supplied AABB.
	    public void Query(Func<int, bool> callback, ref AABB aabb)
        {
            stack.Clear();
	        stack.Add(_root);

	        while (stack.Count > 0)
	        {
		        int box2dNodeId = stack.RemoveLast();
		        if (box2dNodeId == NullNode)
		        {
			        continue;
		        }

		        DynamicTreeNode box2dNode = _box2dNodes[box2dNodeId];

                if (AABB.TestOverlap(ref box2dNode.aabb, ref aabb))
		        {
			        if (box2dNode.IsLeaf())
			        {
				        bool proceed = callback(box2dNodeId);
                        if (!proceed)
                        {
                            return;
                        }
			        }
			        else
			        {
                        stack.Add(box2dNode.child1);
				        stack.Add(box2dNode.child2);
			        }
		        }
	        }
        }

	    /// Ray-cast against the proxies in the tree. This relies on the callback
	    /// to perform a exact ray-cast in the case were the proxy contains a Shape.
	    /// The callback also performs the any collision filtering. This has performance
	    /// roughly equal to k * log(n), where k is the number of collisions and n is the
	    /// number of proxies in the tree.
	    /// @param input the ray-cast input data. The ray extends from p1 to p1 + maxFraction * (p2 - p1).
	    /// @param callback a callback class that is called for each proxy that is hit by the ray.
	    internal void RayCast(RayCastCallbackInternal callback, ref RayCastInput input)
        {
	        float2 p1 = input.p1;
	        float2 p2 = input.p2;
	        float2 r = p2 - p1;
	        r = Vector.Normalize(r);

	        // v is perpendicular to the segment.
	        float2 v = MathUtils.Cross(1.0f, r);
	        float2 abs_v = MathUtils.Abs(v);

	        // Separating axis for segment (Gino, p80).
	        // |dot(v, p1 - c)| > dot(|v|, h)

	        float maxFraction = input.maxFraction;

	        // Build a bounding box for the segment.
	        AABB segmentAABB = new AABB();
	        {
		        float2 t = p1 + maxFraction * (p2 - p1);
		        segmentAABB.lowerBound = MathUtils.Min(p1, t);
		        segmentAABB.upperBound = MathUtils.Max(p1, t);
	        }

            stack.Clear();
	        stack.Add(_root);

	        while (stack.Count > 0)
	        {
		        int box2dNodeId = stack.RemoveLast();
		        if (box2dNodeId == NullNode)
		        {
			        continue;
		        }

		        DynamicTreeNode box2dNode = _box2dNodes[box2dNodeId];

		        if (AABB.TestOverlap(ref box2dNode.aabb, ref segmentAABB) == false)
		        {
			        continue;
		        }

		        // Separating axis for segment (Gino, p80).
		        // |dot(v, p1 - c)| > dot(|v|, h)
		        float2 c = box2dNode.aabb.GetCenter();
		        float2 h = box2dNode.aabb.GetExtents();
		        float separation = Math.Abs(Uno.Vector.Dot(v, p1 - c)) - Uno.Vector.Dot(abs_v, h);
		        if (separation > 0.0f)
		        {
			        continue;
		        }

		        if (box2dNode.IsLeaf())
		        {
			        RayCastInput subInput;
			        subInput.p1 = input.p1;
			        subInput.p2 = input.p2;
			        subInput.maxFraction = maxFraction;

		        	float value = callback(ref subInput, box2dNodeId);

		            if (value == 0.0f)
                    {
                        // the client has terminated the raycast.
				        return;
			        }

			        if (value > 0.0f)
			        {
                        // Update segment bounding box.
                        maxFraction = value;
                        float2 t = p1 + maxFraction * (p2 - p1);
				        segmentAABB.lowerBound = MathUtils.Min(p1, t);
                        segmentAABB.upperBound = MathUtils.Max(p1, t);
			        }
		        }
		        else
		        {
                    stack.Add(box2dNode.child1);
			        stack.Add(box2dNode.child2);
		        }
	        }
        }

        private int CountLeaves(int box2dNodeId)
        {
	        if (box2dNodeId == NullNode)
	        {
		        return 0;
	        }

	        DynamicTreeNode box2dNode = _box2dNodes[box2dNodeId];

	        if (box2dNode.IsLeaf())
	        {
		        return 1;
	        }

	        int count1 = CountLeaves(box2dNode.child1);
	        int count2 = CountLeaves(box2dNode.child2);
	        int count = count1 + count2;
	        return count;
        }

        private void Validate()
        {
	        CountLeaves(_root);
        }

        private int AllocateNode()
        {
	        // Expand the box2dNode pool as needed.
	        if (_freeList == NullNode)
	        {
		        // The free list is empty. Rebuild a bigger pool.
		        DynamicTreeNode[] oldNodes = _box2dNodes;
		        _box2dNodeCapacity *= 2;
                _box2dNodes = new DynamicTreeNode[_box2dNodeCapacity];
                Array.Copy(oldNodes, _box2dNodes, _box2dNodeCount);

		        // Build a linked list for the free list. The parent
		        // pointer becomes the "next" pointer.
		        for (int i = _box2dNodeCount; i < _box2dNodeCapacity - 1; ++i)
		        {
                    _box2dNodes[i].parentOrNext = i + 1;
		        }
		        _box2dNodes[_box2dNodeCapacity-1].parentOrNext = NullNode;
		        _freeList = _box2dNodeCount;
	        }

	        // Peel a box2dNode off the free list.
	        int box2dNodeId = _freeList;
            _freeList = _box2dNodes[box2dNodeId].parentOrNext;
            _box2dNodes[box2dNodeId].parentOrNext = NullNode;
	        _box2dNodes[box2dNodeId].child1 = NullNode;
	        _box2dNodes[box2dNodeId].child2 = NullNode;
            _box2dNodes[box2dNodeId].leafCount = 0;
	        ++_box2dNodeCount;
	        return box2dNodeId;
        }

        private void FreeNode(int box2dNodeId)
        {
            _box2dNodes[box2dNodeId].parentOrNext = _freeList;
	        _freeList = box2dNodeId;
	        --_box2dNodeCount;
        }

        private void InsertLeaf(int leaf)
        {
            ++_insertionCount;

	        if (_root == NullNode)
	        {
		        _root = leaf;
		        _box2dNodes[_root].parentOrNext = NullNode;
		        return;
	        }

	        // Find the best sibling for this box2dNode
	        AABB leafAABB = _box2dNodes[leaf].aabb;
	        float2 leafCenter = leafAABB.GetCenter();
	        int sibling = _root;
	        while (_box2dNodes[sibling].IsLeaf() == false)
	        {
		        // Expand the box2dNode's AABB.
		        _box2dNodes[sibling].aabb.Combine(ref leafAABB);
		        _box2dNodes[sibling].leafCount += 1;

		        int child1 = _box2dNodes[sibling].child1;
		        int child2 = _box2dNodes[sibling].child2;

/*#if false
		        // This seems to create imbalanced trees
		        float2 delta1 = Math.Abs(_box2dNodes[child1].aabb.GetCenter() - leafCenter);
		        float2 delta2 = Math.Abs(_box2dNodes[child2].aabb.GetCenter() - leafCenter);

		        float norm1 = delta1.x + delta1.y;
		        float norm2 = delta2.x + delta2.y;
#else*/
		        // Surface area heuristic
		        AABB aabb1 = new AABB();
                AABB  aabb2 = new AABB();
		        aabb1.Combine(ref leafAABB, ref _box2dNodes[child1].aabb);
		        aabb2.Combine(ref leafAABB, ref _box2dNodes[child2].aabb);
		        float norm1 = (_box2dNodes[child1].leafCount + 1) * aabb1.GetPerimeter();
		        float norm2 = (_box2dNodes[child2].leafCount + 1) * aabb2.GetPerimeter();
//#endif

		        if (norm1 < norm2)
		        {
			        sibling = child1;
		        }
		        else
		        {
			        sibling = child2;
		        }
	        }

	        // Create a new parent for the siblings.
	        int oldParent = _box2dNodes[sibling].parentOrNext;
	        int newParent = AllocateNode();
            _box2dNodes[newParent].parentOrNext = oldParent;
	        _box2dNodes[newParent].userData = null;
	        _box2dNodes[newParent].aabb.Combine(ref leafAABB, ref _box2dNodes[sibling].aabb);
	        _box2dNodes[newParent].leafCount = _box2dNodes[sibling].leafCount + 1;

	        if (oldParent != NullNode)
	        {
		        // The sibling was not the root.
		        if (_box2dNodes[oldParent].child1 == sibling)
		        {
			        _box2dNodes[oldParent].child1 = newParent;
		        }
		        else
		        {
			        _box2dNodes[oldParent].child2 = newParent;
		        }

		        _box2dNodes[newParent].child1 = sibling;
		        _box2dNodes[newParent].child2 = leaf;
                _box2dNodes[sibling].parentOrNext = newParent;
                _box2dNodes[leaf].parentOrNext = newParent;
	        }
	        else
	        {
		        // The sibling was the root.
		        _box2dNodes[newParent].child1 = sibling;
		        _box2dNodes[newParent].child2 = leaf;
                _box2dNodes[sibling].parentOrNext = newParent;
                _box2dNodes[leaf].parentOrNext = newParent;
		        _root = newParent;
	        }
        }

        private void RemoveLeaf(int leaf)
        {
            if (leaf == _root)
	        {
		        _root = NullNode;
		        return;
	        }

            int parent = _box2dNodes[leaf].parentOrNext;
            int grandParent = _box2dNodes[parent].parentOrNext;
	        int sibling;
	        if (_box2dNodes[parent].child1 == leaf)
	        {
		        sibling = _box2dNodes[parent].child2;
	        }
	        else
	        {
		        sibling = _box2dNodes[parent].child1;
	        }

	        if (grandParent != NullNode)
	        {
		        // Destroy parent and connect sibling to grandParent.
		        if (_box2dNodes[grandParent].child1 == parent)
		        {
			        _box2dNodes[grandParent].child1 = sibling;
		        }
		        else
		        {
			        _box2dNodes[grandParent].child2 = sibling;
		        }
                _box2dNodes[sibling].parentOrNext = grandParent;
		        FreeNode(parent);

		        // Adjust ancestor bounds.
		        parent = grandParent;
		        while (parent != NullNode)
		        {
			        AABB oldAABB = _box2dNodes[parent].aabb;
			        _box2dNodes[parent].aabb.Combine(ref _box2dNodes[_box2dNodes[parent].child1].aabb, ref _box2dNodes[_box2dNodes[parent].child2].aabb);

			        _box2dNodes[parent].leafCount -= 1;

                    parent = _box2dNodes[parent].parentOrNext;
		        }
	        }
	        else
	        {
		        _root = sibling;
                _box2dNodes[sibling].parentOrNext = NullNode;
		        FreeNode(parent);
	        }
        }

        private int ComputeHeight(int box2dNodeId)
        {
		    if (box2dNodeId == NullNode)
	        {
		        return 0;
	        }

	        DynamicTreeNode box2dNode = _box2dNodes[box2dNodeId];
	        int height1 = ComputeHeight(box2dNode.child1);
	        int height2 = ComputeHeight(box2dNode.child2);
	        return 1 + Math.Max(height1, height2);
        }

	    int _root;

	    DynamicTreeNode[] _box2dNodes;
	    int _box2dNodeCount;
	    int _box2dNodeCapacity;

	    int _freeList;

	    /// This is used incrementally traverse the tree for re-balancing.
	    int _path;

        int _insertionCount;
    }
}

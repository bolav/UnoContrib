using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;

namespace Uno.Physics.Box2D
{
	public class Queue<T>
	{
		List<T> q = new List<T>();
		public void Enqueue(T t) { q.Add(t); }
		public T Dequeue() 
		{ 
			var t = q[0];
			q.RemoveAt(0); 
			return t;
		}
		public int Count { get { return q.Count; } }
	}
}
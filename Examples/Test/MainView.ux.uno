using Fuse.Shapes;
using Uno.Geometry;
using Fuse.Entities;
using Fuse.Time;
using Fuse;
using Uno.Collections;
using Uno.Math;
using Fuse.Triggers;

public partial class MainView
{
	sealed class Tiervenn_Canvas_XY_Property: global::Uno.UX.Property<float2>
	{
		Ball _obj;
		public Tiervenn_Canvas_XY_Property(Ball obj) { _obj = obj; }
		protected override float2 OnGet() {
			var x = global::Fuse.Controls.Canvas.GetX(_obj);
			var y = global::Fuse.Controls.Canvas.GetY(_obj);
			return float2(x,y);
		}
		protected override void OnSet(float2 v) {
			global::Fuse.Controls.Canvas.SetX(_obj, v.X);
			global::Fuse.Controls.Canvas.SetY(_obj, v.Y);
			var line = _obj.Linje;
			if (line != null) {
				line.SetFrom(_obj);
			}
		}
	}

	List<Ball> balls = new List<Ball>();
	Tallinje TLinje1;

	// 63, 195, 336, 493, 663, 776, 876
	int[] LineX = new int[7] {63, 195, 336, 493, 663, 776, 876};

	public MainView()
	{
		InitializeUX();
		HitTestMode = HitTestMode.Bounds;

		BeforeDraw += OnBeforeDraw;
		PointerPressed += OnPressed;
		PointerMoved += OnMoved;
		PointerReleased += OnReleased;

		var ball = new Ball();
		balls.Add(ball);
		TLinje1 = new Tallinje();

		MainPanel.Children.Add(TLinje1);
		MainPanel.Children.Add(ball);
	}
	
	float2 oldsize;

	// TLinje1, X + 62, OSize = 931 x 196
	float LineY;
	float BallSize;
	public void OnBeforeDraw (object o, Fuse.DrawArgs args) {
		if (oldsize != ActualSize) {
			debug_log "OnResized " + ActualSize;
			BallSize = ActualSize.X / 10;

			TLinje1.Width = ActualSize.X; // 931 x 196
			TLinje1.Height = ActualSize.X / 4.75f;
			global::Fuse.Controls.Canvas.SetX(TLinje1, 0);
			global::Fuse.Controls.Canvas.SetY(TLinje1, ActualSize.Y - TLinje1.Height);
			LineY = ActualSize.Y - TLinje1.Height + (62 * TLinje1.Height / 196);

			foreach (var b in balls) {
				b.Width = BallSize;
				b.Height = BallSize;
				var bx = global::Fuse.Controls.Canvas.GetX(b);
				AnimateTo(b, bx);

			}
			oldsize = ActualSize;
		}
	}

	public void AnimateTo (Ball b, float tox) {
		Fuse.Triggers.Manual t = b.Trigger as Fuse.Triggers.Manual;
		float duration = 50;
		if (t == null) {
			t = new Fuse.Triggers.Manual();
			b.Trigger = t;
		}
		else {
			double rest;
			Fuse.Triggers.LinearPlayer.Disable(b, t, out rest);
			duration = (float)rest;
			t.Animators.Clear();
		}
		var target = new Tiervenn_Canvas_XY_Property(b);
		var node = new Fuse.Animations.ChangeFloat2()
		{
			Target = target,
			Value = float2(tox, LineY - (b.Height / 2)),
			Duration = duration,
			Easing = Fuse.Animations.Easing.Linear
		};

		t.Animators.Add(node);
		Fuse.Triggers.LinearPlayer.Play(b, t, PlayDirection.Forward, false); // , doneCallback
	}

	int _down = -1;
	Linje DrawLine;
	Ball DrawBall;
	public void OnPressed (object o, Fuse.PointerPressedArgs args) {
		debug_log "OnPressed " + args.PointCoord;
		var virtualCoord = args.PointCoord / AbsoluteZoom;
		virtualCoord -= ActualPosition;

		// var box = new Box();
		// box.Width = BallSize;
		// box.Height = BallSize;
		// MainPanel.Children.Add(box);
		// global::Fuse.Controls.Canvas.SetY(box, virtualCoord.Y - (BallSize / 2));
		// global::Fuse.Controls.Canvas.SetX(box, virtualCoord.X - (BallSize / 2));

		foreach (var b in balls) {
			var y = global::Fuse.Controls.Canvas.GetY(b);
			var x = global::Fuse.Controls.Canvas.GetX(b);
			debug_log "Check " + virtualCoord;
			debug_log "for x: " + x + ", " + (x + b.Width);
			debug_log "for y: " + y + ", " + (y + b.Height);
			if (virtualCoord.X > x && virtualCoord.X < (x + b.Width) && virtualCoord.Y > y && virtualCoord.Y < (y + b.Height)) {
				debug_log "inside ball";
				// TODO: Check if this already have a line, and use it if it exists
				Linje line = b.Linje;
				if (line == null) {
					line = new Linje();
					b.Linje = line;
					this.Children.Add(line);
				}
				DrawLine = line;
				DrawBall = b;
				line.SetTo(FromAbsolute(args.PointCoord));
				line.SetFrom(b);
			}
		}
		_down = args.PointIndex;
	}

	public void OnMoved (object o, Fuse.PointerMovedArgs args) {
		if (_down == args.PointIndex && Input.IsPointerPressed(args.PointIndex)) {
			if (DrawLine != null) {
				DrawLine.SetTo(FromAbsolute(args.PointCoord));
			}
		}
	}

	public void OnReleased (object o, Fuse.PointerReleasedArgs args) {
		if (_down == args.PointIndex && DrawLine != null) {
			if (args.IsPointerCaptured) args.ReleasePointer();
			var virtualCoord = FromAbsolute(args.PointCoord);
			if (virtualCoord.Y > (LineY - (BallSize / 2)) && virtualCoord.Y < (LineY + (BallSize / 2))) {
				debug_log "Released on Line " + virtualCoord.X;
				var diff = virtualCoord.X;
				var found = -1;
				var foundX = diff;
				for (var i = 0; i<LineX.Length; i++) {
					var ci = (LineX[i] * TLinje1.Height / 196);
					var idiff = Abs(virtualCoord.X - ci);
					if (idiff < diff) {
						diff = idiff;
						found = i;
						foundX = ci;
					}
				}
				DrawLine.SetTo(float2( foundX, LineY));
				AnimateTo(DrawBall, foundX - (DrawBall.Width / 2));
			}
			else {
				this.Children.Remove(DrawLine);
				DrawBall.Linje = null;
			}
			DrawLine = null;
			DrawBall = null;
			_down = -1;
		}
	}
}
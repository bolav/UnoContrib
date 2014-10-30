
using Uno;
using Uno.Collections;

public partial class Level3
{
    public Level3()
    {
        // InitializeUX();
        PhysicsBall1 = new AngryBlocks.PhysicsBall()
        {
            Radius = 4f,
            Position = float2(7f, -26f),
            BodyType = (Uno.Physics.Box2D.BodyType)2,
            MaxImpulse = 5f
        };
    }
}

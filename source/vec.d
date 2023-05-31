module vec;

import std.algorithm : clamp, min, max;
import std.array : array;
import std.math : sqrt, cos, sin;
import std.range : repeat;

public
{
	alias v2 = Vec!2;
	alias v3 = Vec!3;
	alias v4 = Vec!4;
}

public union Vec(int size)
{
	static assert(size >= 1);
	static assert(size <= 4);

	alias e this;

	private alias V = Vec!(size);

	struct
	{
		static if (size == 1)
		{
			float x = 0f;
		}

		static if (size == 2)
		{
			float x = 0f;
			float y = 0f;
		}

		static if (size == 3)
		{
			union
			{
				struct
				{
					float x = 0f;
					float y = 0f;
				}

				v2 xy;
			}

			float z = 0f;
		}

		static if (size == 4)
		{
			union
			{
				struct
				{
					union
					{
						struct
						{
							float x = 0f;
							float y = 0f;
						}

						v2 xy;
					}

					float z = 0f;
				}

				v3 xyz;
			}

			float w = 0f;
		}
	}

	float[size] e;

	this(float[size] e...)
	{
		this.e = e[0 .. size];
	}

	this(float[size] e)
	{
		this.e = e;
	}

	static if (size > 2)
	{
		this(Vec!(size - 1) v, float f)
		{
			this.e[0 .. v.e.length] = v.e;
			this.e[$ - 1] = f;
		}
	}

	static if (size < 4)
	{
		this(Vec!(size + 1) v)
		{
			this.e = v.e[0 .. $ - 1];
		}
	}

	unittest
	{
		const v1 = V3(1f, 2f, 3f);
		assert(v1.xy.e == [1f, 2f]);

		const v2 = V4(1f, 2f, 3f, 4f);
		assert(v2.xyz.e == [1f, 2f, 3f]);

		const v3 = V4(v1, 0f);
		assert(v3.e == [1f, 2f, 3f, 0f]);

		const v5 = V2(v1);
		assert(v5.e == [1f, 2f]);
	}

	V clamp(in float min = 0f, in float max = 1f)
	{
		V result = V(this.e);
		foreach (ref float v; result.e)
		{
			v = v.clamp(min, max);
		}
		return result;
	}

	unittest
	{
		V2 v = V2(10f, -19f);

		assert(v.clamp().e == [1f, 0f]);
	}

	V min(in float value)
	{
		V result = V(this.e);
		foreach (ref float v; result.e)
		{
			v = v.min(value);
		}
		return result;
	}

	unittest
	{
		V2 v = V2(10f, -19f);

		assert(v.min(1f).e == [1f, -19f]);
	}

	V max(in float value)
	{
		V result = V(this.e);
		foreach (ref float v; result.e)
		{
			v = v.max(value);
		}
		return result;
	}

	unittest
	{
		V2 v = V2(10f, -19f);

		assert(v.max(1f).e == [10f, 1f]);
	}

	V hadamard(in V rhs) const
	{
		V result = V(this.e);
		foreach (int index, ref float v; result.e)
		{
			v *= rhs.e[index];
		}
		return result;
	}

	unittest
	{
		V2 v = V2(2f, 3f);
		const V2 had = v.hadamard(V2(3f, 2f));

		assert(had.x == 6);
		assert(had.y == 6);
	}

	float dot(in V rhs) const
	{
		float acc = 0f;
		foreach (int index, float v; this.e)
		{
			acc += v * rhs.e[index];
		}
		return acc;
	}

	unittest
	{
		V2 v = V2(3f, 4f);
		assert(v.dot(v) == 25f);
	}

	float magnitudeSquared() const
	{
		return dot(this);
	}

	unittest
	{
		const V2 v = V2(3f, 4f);
		assert(v.magnitudeSquared == 25f);
	}

	float magnitude() const
	{
		return magnitudeSquared.sqrt;
	}

	unittest
	{
		const V2 v = V2(3f, 4f);
		assert(v.magnitude == 5f);
	}

	void magnitude(in float v)
	in (v != 0f)
	{
		this *= v / magnitude();
	}

	unittest
	{
		V2 v = V2(6f, 8f);
		v.magnitude = 5f;

		assert(v.e == [3f, 4f]);
	}

	V normalized()
	{
		V v = V(this.e);
		v.magnitude = 1;
		return v;
	}

	V lerp(in V rhs, float t = 0.5f) const
	{
		return (1.0f - t) * this + t * rhs;
	}

	V opBinary(string op)(in float rhs) const if (op == "*" || op == "/")
	{
		V result = V(this.e);
		foreach (ref float v; result.e)
		{
			mixin("v" ~ op ~ "= rhs;");
		}
		return result;
	}

	V opBinaryRight(string op)(in float rhs) const if (op == "*" || op == "/")
	{
		mixin("return this" ~ op ~ "rhs;");
	}

	unittest
	{
		V2 v = V2(3f, 4f);
		assert((v * 2).e == [6f, 8f]);
		assert((2 * v).e == [6f, 8f]);
		assert((0.5f * v).e == (v / 2).e);
	}

	V opBinary(string op)(in V rhs) const if (op == "+" || op == "-")
	{
		V result = V(this.e);
		foreach (int index, ref float v; result.e)
		{
			mixin("v" ~ op ~ "= rhs.e[index];");
		}
		return result;
	}

	unittest
	{
		V2 v1 = V2(1f, 2f);
		V2 v2 = V2(2f, 3f);
		assert((v1 + v2).e == [3f, 5f]);
		assert((v2 + v1).e == [3f, 5f]);
	}

	V opUnary(string op)() const if (op == "-")
	{
		V result = V(this.e);
		foreach (ref float v; result.e)
		{
			v = -v;
		}
		return result;
	}

	unittest
	{
		V2 v = V2(1f, 1f);
		assert((-v).e == [-1f, -1f]);
	}

	V opOpAssign(string op)(in float rhs) if (op == "*" || op == "/")
	{
		foreach (ref float v; this.e)
		{
			mixin("v" ~ op ~ "= rhs;");
		}
		return this;
	}

	unittest
	{
		V2 v = V2(1f, 2f);
		v *= 2f;
		assert(v.e == [2f, 4f]);
	}

	V opOpAssign(string op)(in V rhs) if (op == "+" || op == "-")
	{
		foreach (int index, ref float v; this.e)
		{
			mixin("v" ~ op ~ "= rhs.e[index];");
		}
		return this;
	}

	unittest
	{
		V2 v1 = V2(1f, 2f);
		V2 v2 = V2(2f, 3f);
		v1 += v2;
		assert(v1.e == [3f, 5f]);
	}

	V perp()
	{
		// TODO: V3??
		V v;
		v.x = -y;
		v.y = x;
		return v;
	}

	string toString() const
	{
		import std.string;

		return format("%s", e);
	}

	unittest
	{
		V2 v = V2(1, 2);
		assert(v.perp.e == [-2, 1]);
	}

	static V zero()
	{
		return V(0f.repeat(size).array[0 .. size]);
	}

	static V one()
	{
		return V(1f.repeat(size).array[0 .. size]);
	}

	unittest
	{
		assert(V2.zero.e == [0f, 0f]);
		assert(V3.zero.e == [0f, 0f, 0f]);
		assert(V4.zero.e == [0f, 0f, 0f, 0f]);

		assert(V2.one.e == [1f, 1f]);
		assert(V3.one.e == [1f, 1f, 1f]);
		assert(V4.one.e == [1f, 1f, 1f, 1f]);
	}

	static V up()
	{
		V v = V(0f.repeat(size).array[0 .. size]);
		v.y = 1f;
		return v;
	}

	static V down()
	{
		return -(V.up);
	}

	unittest
	{
		assert(V2.up.e == [0f, 1f]);
		assert(V3.up.e == [0f, 1f, 0f]);
		assert(V4.up.e == [0f, 1f, 0f, 0f]);
	}

	static V right()
	{
		V v = V(0f.repeat(size).array[0 .. size]);
		v.x = 1f;
		return v;
	}

	static V left()
	{
		return -(V.right);
	}

	unittest
	{
		assert(V2.right.e == [1f, 0f]);
		assert(V3.right.e == [1f, 0f, 0f]);
		assert(V4.right.e == [1f, 0f, 0f, 0f]);
	}

	static if (size == 2)
	{
		static V arm2(float angle)
		{
			return V(cos(angle), sin(angle));
		}
	}
}

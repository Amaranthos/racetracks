import bindbc.sdl;
import bindbc.opengl;

import std.algorithm;
import std.math;
import std.random;
import std.range;
import std.stdio;
import std.string;

import shader;
import vec;

enum canvasRange = 0.9;

int main()
{
	SDLSupport sdlStatus = loadSDL();
	if (sdlStatus != sdlSupport)
	{
		writeln("Failed loading SDL: ", sdlStatus);
		return 1;
	}

	if (SDL_Init(SDL_INIT_VIDEO) < 0)
		throw new SDLException();

	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

	auto window = SDL_CreateWindow("OpenGL 3.2 App", SDL_WINDOWPOS_UNDEFINED,
		SDL_WINDOWPOS_UNDEFINED, 1280, 720, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
	if (!window)
		throw new SDLException();

	const context = SDL_GL_CreateContext(window);
	if (!context)
		throw new SDLException();

	if (SDL_GL_SetSwapInterval(1) < 0)
		writeln("Failed to set VSync");

	GLSupport glStatus = loadOpenGL();
	if (glStatus < glSupport)
	{
		writeln("Failed loading minimum required OpenGL version: ", glStatus);
		return 1;
	}

	loadScene();
	scope (exit)
		unloadScene();

	bool quit = false;
	SDL_Event event;
	while (!quit)
	{
		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
			case SDL_QUIT:
				quit = true;
				break;

			case SDL_KEYDOWN:
				switch (event.key.keysym.scancode)
				{
				case SDL_SCANCODE_ESCAPE:
					quit = true;
					break;

				case SDL_SCANCODE_1:
					showPath = !showPath;
					break;

				case SDL_SCANCODE_2:
					showDebug = !showDebug;
					break;

				case SDL_SCANCODE_SPACE:
					genTrack();
					break;

				default:
					break;
				}
				break;

			default:
				break;
			}
		}

		renderScene();

		SDL_GL_SwapWindow(window);
	}

	return 0;
}

struct Points
{
	v2[] points;
	GLuint buffer;

	alias points this;

	~this()
	{
		glDeleteBuffers(1, &buffer);
	}

	void bufferData(v2[] _points)
	{
		points = _points.dup;

		if (!buffer)
		{
			glGenBuffers(1, &buffer);
		}

		glBindBuffer(GL_ARRAY_BUFFER, buffer);
		glBufferData(GL_ARRAY_BUFFER, v2.sizeof * points.length, points.ptr.ptr, GL_STATIC_DRAW);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
	}

	void draw(GLuint drawMode = GL_POINTS)
	{
		glBindBuffer(GL_ARRAY_BUFFER, buffer);
		glVertexAttribPointer(0, 2, GL_FLOAT, false, 0, null);
		glDrawArrays(drawMode, 0, cast(uint) points.length);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
	}
}

GLuint vertexArrayID;

Points axisPoints;
Points randomPoints;
Points hullPoints;
Points midPoints;
Points controlPoints;
Points pathPoints;
Points debugPoints;

Shader red;
Shader white;
Shader grey;
Shader blue;
Shader yellow;
Shader cyan;
Shader magenta;

bool showPath = true;
bool showDebug;

bool sortByMag(in v2 a, in v2 b)
{
	return a.magnitudeSquared > b.magnitudeSquared;
}

bool sortByAngle(in v2 a, in v2 b)
{
	return atan2(a.y, a.x) > atan2(b.y, b.x);
}

bool sortByCoords(in v2 a, in v2 b)
{
	return a[0] < b[0] || (a[0] == b[0] && a[1] < b[1]);
}

void genTrack()
{
	pathPoints.bufferData(
		genRandomPoints()
			.sort!sortByAngle
			.array // .convexHull()
			.addControlPoints()
			.fixAngles() // .catamulRomChain()
			
	);
}

void loadScene()
{
	// create OpenGL buffers for vertex position and color data
	glGenVertexArrays(1, &vertexArrayID);
	glBindVertexArray(vertexArrayID);

	genTrack();

	// load position data
	axisPoints.bufferData([
		v2(0.0, -1.0), v2(0.0, 1.0), v2(-1.0, 0.0), v2(1.0, 0.0)
	]);

	// link shaders
	red = new Shader("../views/shader.vert", "../views/shader.frag");
	red.use;
	red.setVec3("colour", [1.0, 0.0, 0.0]);

	white = new Shader("../views/shader.vert", "../views/shader.frag");
	white.use;
	white.setVec3("colour", [1.0, 1.0, 1.0]);

	grey = new Shader("../views/shader.vert", "../views/shader.frag");
	grey.use;
	grey.setVec3("colour", [0.1, 0.1, 0.1]);

	blue = new Shader("../views/shader.vert", "../views/shader.frag");
	blue.use;
	blue.setVec3("colour", [0.0, 0.0, 1.0]);

	yellow = new Shader("../views/shader.vert", "../views/shader.frag");
	yellow.use;
	yellow.setVec3("colour", [1.0, 1.0, 0.0]);

	cyan = new Shader("../views/shader.vert", "../views/shader.frag");
	cyan.use;
	cyan.setVec3("colour", [0.0, 1.0, 1.0]);

	magenta = new Shader("../views/shader.vert", "../views/shader.frag");
	magenta.use;
	magenta.setVec3("colour", [1.0, 0.0, 1.0]);

	glEnable(GL_PROGRAM_POINT_SIZE);
	glPointSize(5.0f);
}

void unloadScene()
{
	glDeleteVertexArrays(1, &vertexArrayID);
}

void renderScene()
{
	glClear(GL_COLOR_BUFFER_BIT);

	glEnableVertexAttribArray(0);

	grey.use();
	axisPoints.draw(GL_LINES);

	// draw path
	if (showPath)
	{
		white.use();
		pathPoints.draw(GL_LINE_LOOP);
	}

	blue.use();
	randomPoints.draw();

	red.use();
	hullPoints.draw();

	yellow.use();
	controlPoints.draw();

	magenta.use();
	midPoints.draw();

	if (showDebug)
	{
		cyan.use();
		debugPoints.draw(GL_LINES);
	}

	glDisableVertexAttribArray(0);
}

v2[] genRandomPoints(in uint count = 10)
{
	v2[] res;
	foreach (_; 0 .. count)
	{
		res ~= v2(
			uniform!"()"(-canvasRange, canvasRange),
			uniform!"()"(-canvasRange, canvasRange)
		);
	}

	randomPoints.bufferData(res);

	return res;
}

v2[] convexHull(in v2[] points)
{
	v2[] p = points.dup;
	if (points.length <= 3)
		return p;
	p.sort!(sortByCoords);

	size_t n = points.length, k = 0;
	v2[] h = new v2[](2 * n);

	for (auto i = 0; i < n; ++i)
	{
		while (k >= 2 && cross(h[k - 2], h[k - 1], p[i]) <= 0)
			k--;
		h[k++] = p[i];
	}

	for (auto i = n - 1, t = k + 1; i > 0; --i)
	{
		while (k >= t && cross(h[k - 2], h[k - 1], p[i - 1]) <= 0)
			k--;
		h[k++] = p[i - 1];
	}

	h.length = k - 1;

	hullPoints.bufferData(h);

	return h;
}

v2[] addControlPoints(in v2[] points)
{
	v2[] res;

	v2[] mps;
	v2[] cps;
	v2[] dps;

	v2 randomControlPoint(in v2 a, in v2 b)
	{
		v2 middle = a.lerp(b);

		float length = uniform(0.0, (a - b).magnitude * 0.5);
		v2 random = v2(0.0, 1.0).rotate(uniform01 * 2 * PI);
		random.magnitude = length;
		v2 control = (middle + random).clamp(-canvasRange, canvasRange);

		mps ~= middle;
		cps ~= control;

		dps ~= middle;
		dps ~= control;

		return control;
	}

	foreach (const v2[] pair; points.slide(2))
	{
		res ~= pair[0];
		res ~= randomControlPoint(pair[0], pair[1]);
	}

	res ~= points[$ - 1];
	res ~= randomControlPoint(points[$ - 1], points[0]);

	controlPoints.bufferData(cps);
	midPoints.bufferData(mps);
	debugPoints.bufferData(dps);

	return res;
}

v2[] fixAngles(v2[] points)
{
	foreach (_; 0 .. 100)
	{
		for (int i = 0; i < points.length; ++i)
		{
			auto prev = (i - 1 < 0) ? points[$ - 1] : points[i - 1];
			auto curr = points[i];
			auto next = points[(i + 1) % $];

			v2 pDiff = curr - prev;
			float p1 = sqrt(pDiff.x ^^ 2 + pDiff.y ^^ 2);
			pDiff /= p1;

			v2 nDiff = -(curr - next);
			float n1 = sqrt(nDiff.x ^^ 2 + nDiff.y ^^ 2);
			nDiff /= n1;

			float a = atan2(pDiff.x * nDiff.y - pDiff.y * nDiff.x, pDiff.x * nDiff.x + pDiff.y * nDiff
					.y);

			if (abs(a) < PI_2)
				continue;

			float nA = a.sgn * PI_2;
			float diff = nA - a;
			float cos = cos(diff);
			float sin = sin(diff);

			next = curr + v2(nDiff
					.x * cos - nDiff.y * sin, nDiff
					.x * sin + nDiff.y * cos) * n1;
		}
	}

	return points;
}

v2[] catamulRomChain(in v2[] points, in uint detail = 32)
in (points.length > 3)
{
	v2[] spline;

	foreach (i; 0 .. points.length)
	{
		foreach (t; 1 .. detail)
		{
			spline ~= catamulRomSpline(points[i], points[(i + 1) % $], points[(i + 2) % $], points[(
						i + 3) % $], t / (detail - 1f));
		}
	}

	return spline;
}

v2 catamulRomSpline(in v2 p0, in v2 p1, in v2 p2, in v2 p3, in float t, in float α = 0.5f)
{
	const float k0 = 0.0f;
	float k1 = ((p0 - p1).magnitudeSquared) ^^ (α * 0.5f);
	float k2 = ((p1 - p2).magnitudeSquared) ^^ (α * 0.5f) + k1;
	float k3 = ((p2 - p3).magnitudeSquared) ^^ (α * 0.5f) + k2;

	v2 remap(float a, float b, v2 c, v2 d, float u)
	{
		return lerp(c, d, (u - a) / (b - a));
	}

	float u = lerp(k1, k2, t);
	v2 a1 = remap(k0, k1, p0, p1, u);
	v2 a2 = remap(k1, k2, p1, p2, u);
	v2 a3 = remap(k2, k3, p2, p3, u);
	v2 b1 = remap(k0, k2, a1, a2, u);
	v2 b2 = remap(k1, k3, a2, a3, u);

	return remap(k1, k2, b1, b2, u);
}

float cross(v2 a, v2 b, v2 o)
{
	return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
}

v2 rotate(in v2 v, float rads)
{
	import std.math : sin, cos;

	return v2(
		v.x * cos(rads) - v.y * sin(rads),
		v.x * sin(rads) + v.y * cos(rads)
	);
}

T lerp(T)(in T a, in T b, float t = 0.5f)
{
	return a + t * (b - a);
}

/// Exception for SDL related issues
class SDLException : Exception
{
	/// Creates an exception from SDL_GetError()
	this(string file = __FILE__, size_t line = __LINE__) nothrow @nogc
	{
		super(cast(string) SDL_GetError().fromStringz, file, line);
	}
}

module shader;

import std.file;

import bindbc.opengl;

import std.stdio : writeln;
import std.string : toStringz;

class Shader
{
	uint id;

	this(in string vertex, in string fragment)
	{
		GLint result;

		GLuint vertexShaderID = glCreateShader(GL_VERTEX_SHADER);
		auto vertSource = vertex.readText.toStringz;
		glShaderSource(vertexShaderID, 1, &vertSource, null);
		glCompileShader(vertexShaderID);
		glGetShaderiv(vertexShaderID, GL_COMPILE_STATUS, &result);
		if (!result)
		{
			int infoLogLength;
			glGetShaderiv(vertexShaderID, GL_INFO_LOG_LENGTH, &infoLogLength);
			if (infoLogLength > 0)
			{
				char[] errorMessage = new char[](infoLogLength);
				glGetShaderInfoLog(vertexShaderID, infoLogLength, null, errorMessage.ptr);
				writeln(errorMessage);
			}
		}

		GLuint fragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
		auto fragSource = fragment.readText.toStringz;
		glShaderSource(fragmentShaderID, 1, &fragSource, null);
		glCompileShader(fragmentShaderID);
		glGetShaderiv(fragmentShaderID, GL_COMPILE_STATUS, &result);
		if (!result)
		{
			int infoLogLength;
			glGetShaderiv(fragmentShaderID, GL_INFO_LOG_LENGTH, &infoLogLength);
			if (infoLogLength > 0)
			{
				char[] errorMessage = new char[](infoLogLength);
				glGetShaderInfoLog(fragmentShaderID, infoLogLength, null, errorMessage.ptr);
				writeln(errorMessage);
			}
		}

		// link shaders
		id = glCreateProgram();
		glAttachShader(id, vertexShaderID);
		glAttachShader(id, fragmentShaderID);
		glLinkProgram(id);
		glGetProgramiv(id, GL_LINK_STATUS, &result);
		if (!result)
		{
			int infoLogLength;
			glGetProgramiv(id, GL_INFO_LOG_LENGTH, &infoLogLength);
			if (infoLogLength > 0)
			{
				char[] errorMessage = new char[](infoLogLength);
				glGetProgramInfoLog(id, infoLogLength, null, errorMessage.ptr);
				writeln(errorMessage);
			}
		}

		glDetachShader(id, vertexShaderID);
		glDetachShader(id, fragmentShaderID);

		glDeleteShader(vertexShaderID);
		glDeleteShader(fragmentShaderID);
	}

	~this()
	{
		glDeleteProgram(id);
	}

	void use()
	{
		glUseProgram(id);
	}

	void setBool(in string name, bool value) const
	{
		glUniform1i(glGetUniformLocation(id, name.toStringz), cast(int) value);
	}

	void setInt(in string name, int value) const
	{
		glUniform1i(glGetUniformLocation(id, name.toStringz), value);
	}

	void setFloat(in string name, float value) const
	{
		glUniform1f(glGetUniformLocation(id, name.toStringz), value);
	}

	void setVec3(in string name, in float[3] value) const
	{

		glUniform3fv(glGetUniformLocation(id, name.toStringz), 1, value.ptr);
	}

	void setVec2(in string name, in float[2] value) const
	{

		glUniform2fv(glGetUniformLocation(id, name.toStringz), 1, value.ptr);
	}

	void setMat4(in string name, in float[4][4] value) const
	{

		glUniformMatrix4fv(glGetUniformLocation(id, name.toStringz), 1, GL_FALSE, value.ptr.ptr);
	}
}
